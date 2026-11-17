-- Badge text of an app's Dock tile.
local M = {}

function M.label(appName)
	local dock = hs.application.get("com.apple.dock")
	if not dock then
		return nil
	end
	local ax = hs.axuielement.applicationElement(dock)
	if not ax then
		return nil
	end

	for _, list in ipairs(ax:attributeValue("AXChildren") or {}) do
		if list:attributeValue("AXRole") == "AXList" then
			for _, item in ipairs(list:attributeValue("AXChildren") or {}) do
				if item:attributeValue("AXTitle") == appName then
					local label = item:attributeValue("AXStatusLabel")
					if label and tostring(label) ~= "" then
						return tostring(label)
					end
					return nil
				end
			end
		end
	end
	return nil
end

return M
