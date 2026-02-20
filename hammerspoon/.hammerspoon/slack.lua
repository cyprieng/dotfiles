local slackIndicator = nil

local function updateSlackBadge()
	local output = hs.execute('lsappinfo info -only StatusLabel "Slack"')
	local label = output and output:match('"label"="(.-)"')
	if label and label ~= "" then
		if not slackIndicator then
			slackIndicator = hs.menubar.new(true, "slackIndicator")
			slackIndicator:setTitle("🔴")
		end
	else
		if slackIndicator then
			slackIndicator:delete()
			slackIndicator = nil
		end
	end
end

slackBadgeTimer = hs.timer.doEvery(5, updateSlackBadge)
updateSlackBadge()
