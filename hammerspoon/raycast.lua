local targetAppBundleID1 = "com.raycast.macos"

function bringAppToFront(bundleID)
	local app = hs.application.get(bundleID)
	if app then
		app:activate() -- Brings the app to the front
	else
		hs.application.launchOrFocusByBundleID(bundleID) -- Launch or focus on the app
	end
end

-- Function to check the frontmost window's application
local function checkFrontmostWindow()
	local focusedWindow = hs.window.frontmostWindow()
	if focusedWindow then
		local app = focusedWindow:application()
		local bundleID = app:bundleID()

		-- Check if the frontmost app is Raycast or ChatGPT, and if it is an overlay
		if bundleID == targetAppBundleID1 and not focusedWindow:isStandard() then
			-- hs.alert.show("Raycast Overlay Window Detected")
			bringAppToFront(targetAppBundleID1)
		end
	end
end

-- Use an event tap to trigger the overlay check on every key and mouse click
overlayCheckEventTap = hs.eventtap.new(
	{ hs.eventtap.event.types.flagsChanged, hs.eventtap.event.types.keyDown },
	function()
		checkFrontmostWindow()
		return false -- Pass the event to the next handler
	end
)

overlayCheckEventTap:start()
