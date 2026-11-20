-- Menu bar spending or quotas for each AI provider.
local FETCH_EVERY = 300
local BACKOFF = 900
local CODEX_AUTH = (os.getenv("CODEX_HOME") or (os.getenv("HOME") .. "/.codex")) .. "/auth.json"

local state = {}
local bars = {}
local busy = false

local function readJson(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local raw = file:read("*a")
	file:close()
	return hs.json.decode(raw)
end

local function keychain(service)
	local out, ok = hs.execute(string.format("security find-generic-password -s %q -w", service))
	if not ok or not out or out == "" then
		return nil
	end
	return out:gsub("\n$", "")
end

local function money(cents)
	return string.format("$%d", math.floor(cents / 100 + 0.5))
end

local function utcEpoch(iso)
	if type(iso) ~= "string" then
		return nil
	end
	local y, mo, d, h, mi, s = iso:match("(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)")
	if not y then
		return nil
	end
	local asLocal = os.time({
		year = tonumber(y),
		month = tonumber(mo),
		day = tonumber(d),
		hour = tonumber(h),
		min = tonumber(mi),
		sec = tonumber(s),
	})
	local now = os.time()
	local here = os.date("*t", now)
	local there = os.date("!*t", now)
	here.isdst = false
	there.isdst = false
	return asLocal - os.difftime(os.time(here), os.time(there))
end

local function cents(bucket)
	if type(bucket) ~= "table" or bucket.enabled == false then
		return nil
	end
	local used = tonumber(bucket.used)
	local limit = tonumber(bucket.limit)
	if not used or not limit or limit <= 0 then
		return nil
	end
	return { used = used, limit = limit }
end

-- Cursor's API wants a session cookie built from the keychain JWT.
local function cursorSession(token)
	if not token then
		return nil
	end
	local part = token:match("^[^%.]+%.([^%.]+)")
	if not part then
		return nil
	end
	part = part:gsub("-", "+"):gsub("_", "/")
	local pad = #part % 4
	if pad > 0 then
		part = part .. string.rep("=", 4 - pad)
	end
	local raw = hs.base64.decode(part)
	local payload = raw and hs.json.decode(raw)
	local sub = payload and payload.sub
	if type(sub) ~= "string" or sub == "" then
		return nil
	end
	local userId = sub:match("|(.+)$") or sub
	return "WorkosCursorSessionToken=" .. userId .. "%3A%3A" .. token
end

local function quotaWindow(usedPercent, durationSeconds, resetsAt)
	local used = tonumber(usedPercent)
	local seconds = tonumber(durationSeconds)
	if not used or not seconds or seconds <= 0 then
		return nil
	end
	local label = seconds % 86400 == 0 and string.format("%dj", seconds / 86400)
		or seconds % 3600 == 0 and string.format("%dh", seconds / 3600)
		or string.format("%gmin", seconds / 60)
	return { used = used, label = label, resetsAt = tonumber(resetsAt) }
end

local function quotaPercents(rows)
	local quotas = {}
	for _, row in ipairs(rows) do
		local used = tonumber(row.used)
		if row.label and used then
			table.insert(quotas, { label = row.label, used = used })
		end
	end
	return #quotas > 0 and quotas or nil
end

local function quotaTitle(windows)
	local parts = {}
	for _, window in ipairs(windows) do
		table.insert(parts, string.format("%s %.0f%%", window.label, window.used))
	end
	return table.concat(parts, " · ")
end

local function metricTitle(metric)
	if not metric then
		return "…"
	end
	return metric.windows and quotaTitle(metric.windows) or money(metric.used)
end

-- Every provider maps its API response to one of these shared metric formats:
-- Spending: { used = cents, limit = cents, startsAt = epoch?, resetsAt = epoch?, quotas = { { label, used } }? }
-- Quotas: { windows = { quotaWindow(usedPercent, durationSeconds, resetEpoch), ... } }
-- Titles and menus depend only on these formats, never on the provider.
-- A spending metric with no period uses the current calendar month.
local providers = {
	{
		id = "codex",
		name = "aiUsageCodex",
		icon = "/Applications/ChatGPT.app/Contents/Resources/chatgptTemplate.png",
		available = function()
			return hs.fs.attributes(CODEX_AUTH) ~= nil
		end,
		auth = function()
			local creds = readJson(CODEX_AUTH)
			local tokens = type(creds) == "table" and creds.tokens
			if type(tokens) ~= "table" or type(tokens.access_token) ~= "string" then
				return nil
			end
			local headers = { Authorization = "Bearer " .. tokens.access_token }
			if tokens.account_id then
				headers["ChatGPT-Account-Id"] = tokens.account_id
			end
			return "https://chatgpt.com/backend-api/wham/usage", headers
		end,
		parse = function(data)
			local limits = data.rate_limit
			if type(limits) ~= "table" then
				return nil
			end
			local windows = {}
			for _, key in ipairs({ "primary_window", "secondary_window" }) do
				local bucket = limits[key]
				if type(bucket) == "table" then
					local window = quotaWindow(bucket.used_percent, bucket.limit_window_seconds, bucket.reset_at)
					if window then
						table.insert(windows, window)
					end
				end
			end
			return #windows > 0 and { windows = windows } or nil
		end,
	},
	{
		id = "claude",
		name = "aiUsageClaude",
		icon = "/Applications/Claude.app/Contents/Resources/TrayIconTemplate.png",
		auth = function()
			local raw = keychain("Claude Code-credentials")
			local creds = raw and hs.json.decode(raw)
			local token = creds and creds.claudeAiOauth and creds.claudeAiOauth.accessToken
			if not token then
				return nil
			end
			return "https://api.anthropic.com/api/oauth/usage", { Authorization = "Bearer " .. token }
		end,
		parse = function(data)
			local extra = data.extra_usage
			return extra and cents({
				enabled = extra.is_enabled,
				used = extra.used_credits,
				limit = extra.monthly_limit,
			})
		end,
	},
	{
		id = "cursor",
		name = "aiUsageCursor",
		icon = "/Applications/Cursor.app/Contents/Resources/app/resources/darwin/trayTemplate.png",
		auth = function()
			local session = cursorSession(keychain("cursor-access-token"))
			if not session then
				return nil
			end
			return "https://cursor.com/api/usage-summary", { Cookie = session }
		end,
		parse = function(data)
			local individual = data.individualUsage
			local metric = individual and cents(individual.onDemand)
			if not metric then
				return nil
			end
			metric.startsAt = utcEpoch(data.billingCycleStart)
			metric.resetsAt = utcEpoch(data.billingCycleEnd)
			local plan = type(individual.plan) == "table" and individual.plan or {}
			metric.quotas = quotaPercents({
				{ label = "Modèles Cursor", used = plan.autoPercentUsed },
				{ label = "Autres modèles", used = plan.apiPercentUsed },
			})
			return metric
		end,
	},
}

local function bar(provider)
	local item = hs.menubar.new(true, provider.name)
	if not item then
		return nil
	end
	local image = provider.icon and hs.image.imageFromPath(provider.icon)
	if image then
		item:setIcon(image:setSize({ w = 18, h = 18 }), true)
	end
	return item
end

local function monthPeriod(now)
	local date = os.date("*t", now)
	local startsAt = os.time({ year = date.year, month = date.month, day = 1, hour = 0, min = 0, sec = 0 })
	local year = date.year
	local month = date.month + 1
	if month == 13 then
		year = year + 1
		month = 1
	end
	return startsAt, os.time({ year = year, month = month, day = 1, hour = 0, min = 0, sec = 0 })
end

local function periodBounds(metric, now)
	if metric.startsAt or metric.resetsAt then
		return metric.startsAt, metric.resetsAt
	end
	return monthPeriod(now)
end

local function moneyDaily(centsPerDay)
	return string.format("$%.2f/j", centsPerDay / 100)
end

-- Monday to Friday, holidays included. A day is 86400s of that time.
local function weekdaySeconds(from, to)
	if not from or not to or to <= from then
		return 0
	end
	local seconds = 0
	local cursor = from
	while cursor < to do
		local date = os.date("*t", cursor)
		local midnight = os.time({ year = date.year, month = date.month, day = date.day + 1, hour = 0, min = 0, sec = 0 })
		local sliceEnd = math.min(midnight, to)
		if date.wday >= 2 and date.wday <= 6 then
			seconds = seconds + (sliceEnd - cursor)
		end
		cursor = sliceEnd
	end
	return seconds
end

local function paceItems(metric)
	local now = os.time()
	local startsAt, resetsAt = periodBounds(metric, now)
	local items = {}
	local elapsed = weekdaySeconds(startsAt, now)
	if elapsed >= 3600 then
		table.insert(items, { title = "Moyenne " .. moneyDaily(metric.used / (elapsed / 86400)) })
	end
	local leftSeconds = weekdaySeconds(now, resetsAt)
	if leftSeconds > 0 then
		local left = math.max(metric.limit - metric.used, 0)
		table.insert(items, { title = "À consommer " .. moneyDaily(left / (leftSeconds / 86400)) })
	end
	return items
end

local function detailMenu(metric)
	if not metric then
		return { { title = "Pas récupéré" } }
	end
	if metric.windows then
		local items = {}
		for index, window in ipairs(metric.windows) do
			if index > 1 then
				table.insert(items, { title = "-" })
			end
			table.insert(items, { title = string.format("%s : %.0f%% consommé", window.label, window.used) })
			if window.resetsAt then
				table.insert(items, { title = "Reset " .. os.date("%d/%m %H:%M", window.resetsAt) })
			end
		end
		return items
	end
	local items = { { title = "Plafond " .. money(metric.limit) } }
	for _, item in ipairs(paceItems(metric)) do
		table.insert(items, item)
	end
	local _, resetsAt = periodBounds(metric, os.time())
	if resetsAt then
		table.insert(items, { title = "Reset " .. os.date("%d/%m %H:%M", resetsAt) })
	end
	local quotas = metric.quotas or {}
	if #quotas > 0 then
		table.insert(items, { title = "-" })
		for _, quota in ipairs(quotas) do
			table.insert(items, { title = string.format("%s : %.0f%%", quota.label, quota.used) })
		end
	end
	return items
end

local function show(provider)
	if bars[provider.id] then
		return
	end
	local item = bar(provider)
	if not item then
		return
	end
	item:setMenu(function()
		return detailMenu(state[provider.id])
	end)
	bars[provider.id] = item
end

local function render()
	for _, provider in ipairs(providers) do
		local metric = state[provider.id]
		if metric then
			show(provider)
		end
		local item = bars[provider.id]
		if item then
			if metric then
				item:setTitle(metricTitle(metric))
			else
				item:delete()
				bars[provider.id] = nil
			end
		end
	end
end

local function fetch()
	if busy then
		return
	end

	local jobs = {}
	for _, provider in ipairs(providers) do
		local available = provider.available and provider.available()
			or provider.icon and hs.fs.attributes(provider.icon)
		if available then
			local url, headers = provider.auth()
			if url then
				table.insert(jobs, { provider = provider, url = url, headers = headers })
			else
				state[provider.id] = nil
			end
		else
			state[provider.id] = nil
		end
	end
	render()
	if #jobs == 0 then
		return
	end

	busy = true
	local left = #jobs
	local delay = FETCH_EVERY

	local function done()
		left = left - 1
		if left > 0 then
			return
		end
		busy = false
		if delay == BACKOFF then
			aiUsageTimer:setNextTrigger(BACKOFF)
		end
	end

	for _, job in ipairs(jobs) do
		hs.http.asyncGet(job.url, job.headers, function(status, body)
			local metric
			if status == 429 then
				delay = BACKOFF
			elseif status == 200 and body then
				local data = hs.json.decode(body)
				if type(data) == "table" then
					local ok, parsed = pcall(job.provider.parse, data)
					if ok then
						metric = parsed
					end
				end
			end
			state[job.provider.id] = metric
			render()
			done()
		end)
	end
end

aiUsageTimer = hs.timer.doEvery(FETCH_EVERY, fetch)
fetch()

return { bars = bars, state = state }
