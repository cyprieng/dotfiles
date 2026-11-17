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
-- Spending: { used = cents, limit = cents, resetsAt = epoch? }
-- Quotas: { windows = { quotaWindow(usedPercent, durationSeconds, resetEpoch), ... } }
-- Titles and menus depend only on these formats, never on the provider.
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
			metric.resetsAt = data.billingCycleEnd and utcEpoch(data.billingCycleEnd)
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

local function detailMenu(metric)
	if not metric then
		return { { title = "Pas récupéré" } }
	end
	if metric.windows then
		local items = {}
		for _, window in ipairs(metric.windows) do
			table.insert(items, { title = string.format("%s : %.0f%% consommé", window.label, window.used) })
			if window.resetsAt then
				table.insert(items, { title = "Reset " .. os.date("%d/%m %H:%M", window.resetsAt) })
			end
		end
		return items
	end
	local items = { { title = "Plafond " .. money(metric.limit) } }
	if metric.resetsAt then
		table.insert(items, { title = "Reset " .. os.date("%d/%m %H:%M", metric.resetsAt) })
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
