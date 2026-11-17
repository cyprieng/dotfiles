-- Menu bar dollars for each installed AI app. A provider is one entry in `providers`.
local FETCH_EVERY = 300
local BACKOFF = 900

local state = {}
local bars = {}
local busy = false

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

local providers = {
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
	local image = hs.image.imageFromPath(provider.icon)
	if image then
		item:setIcon(image:setSize({ w = 18, h = 18 }), true)
	end
	return item
end

local function detailMenu(metric)
	if not metric then
		return { { title = "Pas récupéré" } }
	end
	local items = { { title = "Plafond " .. money(metric.limit) } }
	if metric.resetsAt then
		table.insert(items, { title = "Reset " .. os.date("%d/%m %H:%M", metric.resetsAt) })
	end
	return items
end

local function show(provider)
	if bars[provider.id] or not hs.fs.attributes(provider.icon) then
		return
	end
	local item = bar(provider)
	if not item then
		return
	end
	item:setMenu(function()
		return detailMenu(state[provider.id])
	end)
	item:setTitle("…")
	bars[provider.id] = item
end

local function render()
	for id, item in pairs(bars) do
		local metric = state[id]
		item:setTitle(metric and money(metric.used) or "…")
	end
end

local function fetch()
	if busy then
		return
	end

	local jobs = {}
	for _, provider in ipairs(providers) do
		if bars[provider.id] then
			local url, headers = provider.auth()
			if url then
				table.insert(jobs, { provider = provider, url = url, headers = headers })
			end
		end
	end
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
		render()
		if delay == BACKOFF then
			aiUsageTimer:setNextTrigger(BACKOFF)
		end
	end

	for _, job in ipairs(jobs) do
		hs.http.asyncGet(job.url, job.headers, function(status, body)
			if status == 429 then
				delay = BACKOFF
			elseif status == 200 and body then
				local data = hs.json.decode(body)
				local metric = data and job.provider.parse(data)
				if metric then
					state[job.provider.id] = metric
				end
			end
			done()
		end)
	end
end

for _, provider in ipairs(providers) do
	show(provider)
end
aiUsageTimer = hs.timer.doEvery(FETCH_EVERY, fetch)
fetch()
