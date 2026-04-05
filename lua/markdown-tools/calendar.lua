local M = {}

-- Parse time like "3pm", "3:15pm", "15", "15:30", "0300"
local function parse_time(str)
	str = str:lower():gsub("%s+", "")

	local hour, min, ampm

	-- 3:15pm, 12:30am
	hour, min, ampm = str:match("^(%d+):(%d+)([ap]m?)$")
	if not hour then
		-- 3pm, 12am
		hour, ampm = str:match("^(%d+)([ap]m?)$")
		min = "0"
	end
	if not hour then
		-- military: 0300, 1530
		if #str == 4 and str:match("^%d+$") then
			hour = str:sub(1, 2)
			min = str:sub(3, 4)
			ampm = ""
		end
	end
	if not hour then
		-- plain number: 3, 15
		hour = str:match("^(%d+)$")
		min = "0"
		ampm = ""
	end

	if not hour then
		return nil
	end

	hour = tonumber(hour)
	min = tonumber(min)

	if ampm == "pm" or ampm == "p" then
		if hour ~= 12 then
			hour = hour + 12
		end
	elseif ampm == "am" or ampm == "a" then
		if hour == 12 then
			hour = 0
		end
	end

	return { hour = hour, min = min }
end

-- Parse a line like "Task name @ 3pm-4pm" or "Task name @ 2025-01-20 3pm-4pm"
function M.parse_line(line)
	local title, rest = line:match("^(.-)%s*@%s*(.+)$")
	if not title or not rest then
		return nil, "No '@' found. Format: Task name @ 3pm-4pm"
	end

	title = title:gsub("^%s+", ""):gsub("%s+$", "")
	rest = rest:gsub("^%s+", ""):gsub("%s+$", "")

	if title == "" then
		return nil, "No event title before '@'"
	end

	local date, time_range

	-- Try: 2025-01-20 3pm-4pm
	date, time_range = rest:match("^(%d%d%d%d%-%d%d%-%d%d)%s+(.+)$")
	if not date then
		-- No date, just time range — default to today
		date = os.date("%Y-%m-%d")
		time_range = rest
	end

	local start_str, end_str = time_range:match("^(.+)-(.+)$")
	if not start_str or not end_str then
		return nil, "No time range found. Format: 3pm-4pm"
	end

	local start_time = parse_time(start_str)
	local end_time = parse_time(end_str)

	if not start_time then
		return nil, "Could not parse start time: " .. start_str
	end
	if not end_time then
		return nil, "Could not parse end time: " .. end_str
	end

	return {
		title = title,
		date = date,
		start_time = start_time,
		end_time = end_time,
	}
end

-- Create a calendar event via AppleScript (macOS Calendar.app)
function M.create_event(event, calendar_name)
	calendar_name = calendar_name or "Calendar"

	local script = string.format(
		[[
tell application "Calendar"
  tell calendar "%s"
    set startDate to current date
    set year of startDate to %s
    set month of startDate to %s
    set day of startDate to %s
    set hours of startDate to %d
    set minutes of startDate to %d
    set seconds of startDate to 0

    set endDate to current date
    set year of endDate to %s
    set month of endDate to %s
    set day of endDate to %s
    set hours of endDate to %d
    set minutes of endDate to %d
    set seconds of endDate to 0

    make new event with properties {summary:"%s", start date:startDate, end date:endDate}
  end tell
end tell
]],
		calendar_name,
		event.date:sub(1, 4),
		tonumber(event.date:sub(6, 7)),
		tonumber(event.date:sub(9, 10)),
		event.start_time.hour,
		event.start_time.min,
		event.date:sub(1, 4),
		tonumber(event.date:sub(6, 7)),
		tonumber(event.date:sub(9, 10)),
		event.end_time.hour,
		event.end_time.min,
		event.title:gsub('"', '\\"')
	)

	local result = vim.system({ "osascript", "-e", script }):wait()
	if result.code ~= 0 then
		return false, "AppleScript error: " .. (result.stderr or "unknown error")
	end
	return true
end

-- Delete a calendar event by title and date via AppleScript
function M.delete_event(event, calendar_name)
	calendar_name = calendar_name or "Calendar"

	local script = string.format(
		[[
tell application "Calendar"
  tell calendar "%s"
    set startDate to current date
    set year of startDate to %s
    set month of startDate to %s
    set day of startDate to %s
    set hours of startDate to 0
    set minutes of startDate to 0
    set seconds of startDate to 0

    set endDate to startDate + (1 * days)

    set matchingEvents to (every event whose summary is "%s" and start date >= startDate and start date < endDate)
    repeat with e in matchingEvents
      delete e
    end repeat
    return (count of matchingEvents) as text
  end tell
end tell
]],
		calendar_name,
		event.date:sub(1, 4),
		tonumber(event.date:sub(6, 7)),
		tonumber(event.date:sub(9, 10)),
		event.title:gsub('"', '\\"')
	)

	local result = vim.system({ "osascript", "-e", script }):wait()
	if result.code ~= 0 then
		return false, "AppleScript error: " .. (result.stderr or "unknown error")
	end
	local count = tonumber(result.stdout:match("%d+")) or 0
	if count == 0 then
		return false, "No matching event found"
	end
	return true
end

return M
