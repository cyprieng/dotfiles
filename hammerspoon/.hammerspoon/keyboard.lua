-- Keep track of USB keyboard state
local usbKeyboardConnected = false

-- Input source IDs
local FRENCH_INPUT = "com.apple.keylayout.French"
local US_INTL_INPUT = "com.apple.keyboardlayout.qwerty-fr.keylayout.qwerty-fr"

-- Function to change input source
function changeInputSource(sourceID)
	hs.keycodes.currentSourceID(sourceID)
end

-- Function to check USB keyboard status and change input source
function handleKeyboardConnection()
	local devices = hs.usb.attachedDevices()
	local keyboardFound = false

	-- Check for USB keyboards
	for _, device in pairs(devices) do
		-- You might need to adjust this check based on your keyboard's properties
		if
			device.productName
			and (device.productName:lower():match("xd87") or device.productName:lower():match("hotdox"))
		then
			keyboardFound = true
			break
		end
	end

	-- If keyboard state changed
	if keyboardFound ~= usbKeyboardConnected then
		usbKeyboardConnected = keyboardFound

		if keyboardFound then
			-- When USB keyboard is connected -> US International
			changeInputSource(US_INTL_INPUT)
			hs.alert.show("Switched to US International")
		else
			-- When USB keyboard is disconnected -> French
			changeInputSource(FRENCH_INPUT)
			hs.alert.show("Switched to French")
		end
	end
end

-- Watch for USB device changes
usbWatcher = hs.usb.watcher.new(handleKeyboardConnection)
usbWatcher:start()

-- Initial check
handleKeyboardConnection()
