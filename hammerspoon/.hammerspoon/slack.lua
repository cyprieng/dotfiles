local slackIndicator = nil

local function makeBadgeIcon(text)
	local size = 20
	local yOffset = text:match("^%d+$") and -2 or -3
	local canvas = hs.canvas.new({ x = 0, y = 0, w = size, h = size })
	canvas[1] = {
		type = "circle",
		center = { x = size / 2, y = size / 2 },
		radius = size / 2,
		fillColor = { red = 0.9, green = 0.2, blue = 0.2, alpha = 1 },
		action = "fill",
	}
	canvas[2] = {
		type = "text",
		frame = { x = 0, y = (size - 14) / 2 + yOffset, w = size, h = size },
		text = hs.styledtext.new(text, {
			font = { name = ".AppleSystemUIFontBold", size = 14 },
			color = { white = 1, alpha = 1 },
			paragraphStyle = { alignment = "center" },
		}),
	}
	local icon = canvas:imageFromCanvas()
	canvas:delete()
	return icon
end

local function updateSlackBadge()
	local output = hs.execute('lsappinfo info -only StatusLabel "Slack"')
	local label = output and output:match('"label"="(.-)"')
	if label and label ~= "" then
		if not slackIndicator then
			slackIndicator = hs.menubar.new(true, "slackIndicator")
		end
		slackIndicator:setIcon(makeBadgeIcon(label), false)
		slackIndicator:setTitle("")
	else
		if slackIndicator then
			slackIndicator:delete()
			slackIndicator = nil
		end
	end
end

slackBadgeTimer = hs.timer.doEvery(5, updateSlackBadge)
updateSlackBadge()
