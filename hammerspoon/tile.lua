-- Define the Hyper key (Cmd + Alt + Ctrl + Shift)
local hyper = { "cmd", "alt", "ctrl", "shift" }

-- Function to calculate distance between two points
local function distance(x1, y1, x2, y2)
	return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

-- Function to tile windows
function tileWindows()
	local screen = hs.screen.mainScreen()
	local windows = hs.window.visibleWindows()
	local screenFrame = screen:frame()

	-- Determine if screen is vertical (height > width)
	local isVertical = screenFrame.h > screenFrame.w

	-- Filter windows on current screen
	local windowsOnScreen = {}
	for _, win in ipairs(windows) do
		if win:screen() == screen and win:title() ~= "" then
			table.insert(windowsOnScreen, win)
		end
	end

	local windowCount = #windowsOnScreen
	if windowCount == 0 then
		return
	end

	-- Calculate grid dimensions based on screen orientation
	local cols, rows
	if isVertical then
		rows = math.ceil(math.sqrt(windowCount))
		cols = math.ceil(windowCount / rows)
	else
		cols = math.ceil(math.sqrt(windowCount))
		rows = math.ceil(windowCount / cols)
	end

	-- Calculate cell dimensions
	local cellWidth = screenFrame.w / cols
	local cellHeight = screenFrame.h / rows

	-- Create array of target positions
	local targetPositions = {}
	for i = 1, windowCount do
		local row, col
		if isVertical then
			-- For vertical screens: fill columns first, then rows
			col = math.floor((i - 1) / rows)
			row = (i - 1) % rows
		else
			-- For horizontal screens: fill rows first, then columns
			row = (i - 1) % rows
			col = math.floor((i - 1) / rows)
		end

		table.insert(targetPositions, {
			index = i,
			x = screenFrame.x + (col * cellWidth) + (cellWidth / 2),
			y = screenFrame.y + (row * cellHeight) + (cellHeight / 2),
		})
	end

	-- Assign windows to nearest target positions
	local assignments = {}
	local usedPositions = {}

	-- For each window, find the nearest available target position
	for _, win in ipairs(windowsOnScreen) do
		local winFrame = win:frame()
		local winCenterX = winFrame.x + (winFrame.w / 2)
		local winCenterY = winFrame.y + (winFrame.h / 2)

		local nearestDist = math.huge
		local nearestPos = nil

		for _, pos in ipairs(targetPositions) do
			if not usedPositions[pos.index] then
				local dist = distance(winCenterX, winCenterY, pos.x, pos.y)
				if dist < nearestDist then
					nearestDist = dist
					nearestPos = pos
				end
			end
		end

		if nearestPos then
			usedPositions[nearestPos.index] = true
			assignments[nearestPos.index] = win
		end
	end

	-- Position windows according to assignments
	for i = 1, windowCount do
		local win = assignments[i]
		if win then
			local row, col
			if isVertical then
				col = math.floor((i - 1) / rows)
				row = (i - 1) % rows
			else
				row = (i - 1) % rows
				col = math.floor((i - 1) / rows)
			end

			local frame = {
				x = screenFrame.x + (col * cellWidth),
				y = screenFrame.y + (row * cellHeight),
				w = cellWidth,
				h = cellHeight,
			}

			-- If it's the last window, give it all remaining space
			if i == windowCount then
				frame.w = screenFrame.w - frame.x + screenFrame.x
				if col == cols - 1 then
					frame.h = screenFrame.h - frame.y + screenFrame.y
				end
			end

			win:setFrame(frame)
		end
	end
end

-- Bind Hyper+T to tile windows
hs.hotkey.bind(hyper, "t", tileWindows)
