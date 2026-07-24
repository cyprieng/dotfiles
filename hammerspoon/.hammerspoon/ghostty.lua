local ghosttyIndicator = nil

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

local function updateGhosttyBadge()
	local output = hs.execute('lsappinfo info -only StatusLabel "Ghostty"')
	local label = output and output:match('"label"="(.-)"')
	if label and label ~= "" then
		if not ghosttyIndicator then
			ghosttyIndicator = hs.menubar.new(true, "ghosttyIndicator")
			ghosttyIndicator:setClickCallback(function()
				hs.application.launchOrFocus("Ghostty")
			end)
		end
		ghosttyIndicator:setIcon(makeBadgeIcon("👻"), false)
		ghosttyIndicator:setTitle("")
	else
		if ghosttyIndicator then
			ghosttyIndicator:delete()
			ghosttyIndicator = nil
		end
	end
end

ghosttyBadgeTimer = hs.timer.doEvery(5, updateGhosttyBadge)
updateGhosttyBadge()
