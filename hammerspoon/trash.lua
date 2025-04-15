-- Function to delete files in trash older than 1 week
function cleanOldTrashFiles()
	-- Get current time
	local currentTime = os.time()
	-- One week in seconds
	local oneWeek = 7 * 24 * 60 * 60

	-- Use AppleScript to get files from trash with their modification dates
	local script = [[
    tell application "Finder"
        set trashItems to items in the trash
        set itemList to {}
        repeat with i from 1 to count of trashItems
            set thisItem to item i of trashItems
            set itemPath to POSIX path of (thisItem as alias)
            set itemDate to modification date of thisItem
            set end of itemList to itemPath & "|" & (itemDate as string)
        end repeat
        return itemList
    end tell
    ]]

	local success, items, rawItems = hs.osascript.applescript(script)

	if success and items then
		for _, itemInfo in ipairs(items) do
			-- Split the string to get path and date
			local path, dateStr = itemInfo:match("(.+)|(.+)")

			if path and dateStr then
				-- Parse date string in format "Monday 9 December 2024 at 18:13:04"
				local dayName, day, monthName, year, hour, min, sec =
					dateStr:match("(%a+)%s+(%d+)%s+(%a+)%s+(%d+)%s+at%s+(%d+):(%d+):(%d+)")

				if day and monthName and year and hour and min and sec then
					-- Convert month name to number
					local months = {
						January = 1,
						February = 2,
						March = 3,
						April = 4,
						May = 5,
						June = 6,
						July = 7,
						August = 8,
						September = 9,
						October = 10,
						November = 11,
						December = 12,
					}
					local month = months[monthName]

					if month then
						local fileTime = os.time({
							year = tonumber(year),
							month = month,
							day = tonumber(day),
							hour = tonumber(hour),
							min = tonumber(min),
							sec = tonumber(sec),
						})

						-- Check if file is older than one week
						if (currentTime - fileTime) > oneWeek then
							-- Use AppleScript to delete the item
							local deleteScript = [[
                            tell application "Finder"
                                delete POSIX file "]] .. path .. [["
                            end tell
                            ]]

							local deleteSuccess = hs.osascript.applescript(deleteScript)
							if deleteSuccess then
								print("Deleted old trash file: " .. path)
							else
								print("Failed to delete: " .. path)
							end
						end
					else
						print("Could not parse month in date: " .. dateStr)
					end
				else
					print("Could not parse date: " .. dateStr)
				end
			end
		end
	else
		print("Could not access Trash items")
	end
end

-- Create a timer to run the cleanup function
trashCleanupTimer = hs.timer.new(3600, cleanOldTrashFiles) -- Run every hour

-- Start the timer
trashCleanupTimer:start()

-- Run once when Hammerspoon loads
cleanOldTrashFiles()
