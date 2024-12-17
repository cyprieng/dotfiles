-- Window Management Configuration
local hyper = { "ctrl", "option" }

-- Helper function to move and resize windows
function moveAndResize(win, x, y, w, h)
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()

	f.x = max.x + (max.w * x)
	f.y = max.y + (max.h * y)
	f.w = max.w * w
	f.h = max.h * h
	win:setFrame(f)
end

-- Helper function to determine if screen is small (MacBook)
function isSmallScreen()
	local screen = hs.screen.mainScreen()
	local res = screen:fullFrame()
	-- Consider screens with height less than 1000 pixels as "small" (typical MacBook)
	return res.h < 1000
end

-- Left half
hs.hotkey.bind(hyper, "left", function()
	local win = hs.window.focusedWindow()
	moveAndResize(win, 0, 0, 0.5, 1)
end)

-- Right half
hs.hotkey.bind(hyper, "right", function()
	local win = hs.window.focusedWindow()
	moveAndResize(win, 0.5, 0, 0.5, 1)
end)

-- Top half
hs.hotkey.bind(hyper, "up", function()
	local win = hs.window.focusedWindow()
	moveAndResize(win, 0, 0, 1, 0.5)
end)

-- Bottom half
hs.hotkey.bind(hyper, "down", function()
	local win = hs.window.focusedWindow()
	moveAndResize(win, 0, 0.5, 1, 0.5)
end)

-- Center
hs.hotkey.bind(hyper, "c", function()
	local win = hs.window.focusedWindow()
	if isSmallScreen() then
		moveAndResize(win, 0.1, 0.1, 0.8, 0.8) -- Larger size for small screens
	else
		moveAndResize(win, 0.15, 0.15, 0.7, 0.7) -- Original size for larger screens
	end
end)

-- Maximize (Rectangle uses Ctrl + Option + Return)
hs.hotkey.bind(hyper, "return", function()
	local win = hs.window.focusedWindow()
	moveAndResize(win, 0, 0, 1, 1)
end)
