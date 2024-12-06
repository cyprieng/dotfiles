-- Define the Hyper key (Cmd + Alt + Ctrl + Shift)
local hyper = { "cmd", "alt", "ctrl", "shift" }

-- Function to tile windows
function tileWindows()
	local screen = hs.screen.mainScreen()
	local windows = hs.window.visibleWindows()
	local screenFrame = screen:frame()

	-- Filter out windows that aren't on the main screen or have no title
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

	-- Calculate grid dimensions based on window count
	local cols = math.ceil(math.sqrt(windowCount))
	local rows = math.ceil(windowCount / cols)

	-- Calculate cell dimensions
	local cellWidth = screenFrame.w / cols
	local cellHeight = screenFrame.h / rows

	-- Position windows in grid (top to bottom, then left to right)
	for i, win in ipairs(windowsOnScreen) do
		local row = (i - 1) % rows
		local col = math.floor((i - 1) / rows)

		local frame = {
			x = screenFrame.x + (col * cellWidth),
			y = screenFrame.y + (row * cellHeight),
			w = cellWidth,
			h = cellHeight,
		}

		-- Si c'est la dernière fenêtre, on lui donne tout l'espace restant
		if i == #windowsOnScreen then
			-- Étendre jusqu'à la fin de la rangée
			frame.w = screenFrame.w - frame.x + screenFrame.x
			-- Si c'est aussi la dernière colonne, étendre jusqu'en bas
			if col == cols - 1 then
				frame.h = screenFrame.h - frame.y + screenFrame.y
			end
		end

		win:setFrame(frame)
	end
end

-- Bind Hyper+T to tile windows
hs.hotkey.bind(hyper, "t", tileWindows)
