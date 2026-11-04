-- Menu bar indicator for each terminal whose Dock icon has a badge (unseen activity)
local apps = {
	{ name = "Ghostty", icon = "👻", autosave = "ghosttyIndicator" },
	{ name = "Rex Beta", icon = "🦖", autosave = "rexIndicator" },
}

local indicators = {}

local function makeBadgeIcon(text)
	local size = 20
	local canvas = hs.canvas.new({ x = 0, y = 0, w = size, h = size })
	canvas[1] = {
		type = "text",
		frame = { x = 0, y = 0, w = size, h = size },
		text = hs.styledtext.new(text, {
			font = { size = 16 },
			paragraphStyle = { alignment = "center" },
		}),
	}
	local icon = canvas:imageFromCanvas()
	canvas:delete()
	return icon
end

local function updateBadge(app)
	local output = hs.execute('lsappinfo info -only StatusLabel "' .. app.name .. '"')
	local label = output and output:match('"label"="(.-)"')
	local indicator = indicators[app.name]
	if label and label ~= "" then
		if not indicator then
			indicator = hs.menubar.new(true, app.autosave)
			indicator:setClickCallback(function()
				hs.application.launchOrFocus(app.name)
			end)
			indicator:setIcon(makeBadgeIcon(app.icon), false)
			indicator:setTitle("")
			indicators[app.name] = indicator
		end
	elseif indicator then
		indicator:delete()
		indicators[app.name] = nil
	end
end

local function updateBadges()
	for _, app in ipairs(apps) do
		updateBadge(app)
	end
end

terminalBadgesTimer = hs.timer.doEvery(5, updateBadges)
updateBadges()
