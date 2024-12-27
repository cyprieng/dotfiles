-- Function to calculate the brightness of an RGB pixel
function calculateBrightness(r, g, b)
	-- Standard formula for perceived brightness
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

-- Function to calculate the saturation of an RGB pixel
function calculateSaturation(r, g, b)
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	if max == 0 then
		return 0
	end
	return (max - min) / max
end

-- Function to convert RGB color to hexadecimal format
function rgbToHex(r, g, b)
	-- Convert values from 0-1 to 0-255 and round to integer
	local r255 = math.floor(r * 255 + 0.5)
	local g255 = math.floor(g * 255 + 0.5)
	local b255 = math.floor(b * 255 + 0.5)
	return string.format("#%02X%02X%02X", r255, g255, b255)
end

-- Function to calculate the average screen color
function getAverageScreenColor()
	-- Capture the main screen
	local screen = hs.screen.mainScreen()
	local screenshot = screen:snapshot()

	-- Get image dimensions
	local size = screenshot:size()
	local width = size.w
	local height = size.h

	-- Variables for color sums
	local totalR, totalG, totalB = 0, 0, 0
	local count = 0

	-- Sample the image every 50 pixels for optimal performance
	for x = 1, width, 50 do
		for y = 1, height, 50 do
			local rgb = screenshot:colorAt({ x = x, y = y })
			local r = rgb.red
			local g = rgb.green
			local b = rgb.blue
			if r and g and b then
				local brightness = calculateBrightness(r, g, b)
				local saturation = calculateSaturation(r, g, b)
				if brightness > 0.4 and brightness < 0.9 and saturation > 0.4 then
					totalR = totalR + r
					totalG = totalG + g
					totalB = totalB + b
					count = count + 1
				end
			end
		end
	end

	-- Calculate average
	local avgR = totalR / count
	local avgG = totalG / count
	local avgB = totalB / count

	return rgbToHex(avgR, avgG, avgB)
end

-- Function to check if device is plugged in
function isPlugged()
	local powerSource = hs.battery.powerSource()
	return powerSource == "AC Power" -- Returns true if plugged in, false if on battery
end

-- Home assistant configuration
local ha_url = "http://10.42.1.1:8123"
local secrets = hs.json.decode(io.open(hs.configdir .. "/secrets.json"):read("*a"))
local token = secrets.ha_token

-- Send color to home assistant
function sendColorToHA(color)
	local headers = {
		["Authorization"] = "Bearer " .. token,
		["Content-Type"] = "application/json",
	}

	local payload = string.format(
		[[
        {
            "state": "%s",
            "attributes": {
                "friendly_name": "Screen Average Color",
                "icon": "mdi:palette",
                "color": "%s"
            }
        }
    ]],
		color,
		color
	)

	hs.http.asyncPost(ha_url .. "/api/states/sensor.screen_color", payload, headers, function(status, body, headers)
		if status == 200 then
			print("Color updated successfully")
		else
			print("Failed to update color:", status, body)
		end
	end)
end

-- Timer to execute capture and sending every 30 seconds
colorTimer = hs.timer.new(60, function()
	if isPlugged() then
		local avgColor = getAverageScreenColor()
		print("Average color:", avgColor)
		sendColorToHA(avgColor)
	end
end)

-- Start the timer
colorTimer:start()
