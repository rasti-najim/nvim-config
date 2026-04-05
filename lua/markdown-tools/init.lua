local M = {}

M.calendar = require("markdown-tools.calendar")

local ns = vim.api.nvim_create_namespace("markdown-tools-cal")
local state_dir = vim.fn.stdpath("data") .. "/markdown-tools"
local state_file = state_dir .. "/scheduled.json"

local function load_state()
	local f = io.open(state_file, "r")
	if not f then
		return {}
	end
	local content = f:read("*a")
	f:close()
	local ok, data = pcall(vim.json.decode, content)
	if ok and data then
		return data
	end
	return {}
end

local function save_state(state)
	vim.fn.mkdir(state_dir, "p")
	local f = io.open(state_file, "w")
	if f then
		f:write(vim.json.encode(state))
		f:close()
	end
end

local function mark_line(buf, line_num)
	vim.api.nvim_buf_set_extmark(buf, ns, line_num - 1, 0, {
		sign_text = "ok",
		sign_hl_group = "DiagnosticOk",
		virt_text = { { " (scheduled)", "DiagnosticOk" } },
		virt_text_pos = "eol",
	})
end

local function restore_marks(buf, filepath)
	local state = load_state()
	local scheduled = state[filepath]
	if not scheduled then
		return
	end
	local line_count = vim.api.nvim_buf_line_count(buf)
	for _, line_text in ipairs(scheduled) do
		local lines = vim.api.nvim_buf_get_lines(buf, 0, line_count, false)
		for i, l in ipairs(lines) do
			if l == line_text then
				mark_line(buf, i)
				break
			end
		end
	end
end

local function remove_scheduled(filepath, line_text)
	local state = load_state()
	if not state[filepath] then
		return
	end
	for i, existing in ipairs(state[filepath]) do
		if existing == line_text then
			table.remove(state[filepath], i)
			break
		end
	end
	if #state[filepath] == 0 then
		state[filepath] = nil
	end
	save_state(state)
end

local function unmark_line(buf, line_num)
	local marks = vim.api.nvim_buf_get_extmarks(buf, ns, { line_num - 1, 0 }, { line_num - 1, -1 }, {})
	for _, mark in ipairs(marks) do
		vim.api.nvim_buf_del_extmark(buf, ns, mark[1])
	end
	vim.api.nvim_buf_set_extmark(buf, ns, line_num - 1, 0, {
		sign_text = "xx",
		sign_hl_group = "DiagnosticError",
		virt_text = { { " (deleted)", "DiagnosticError" } },
		virt_text_pos = "eol",
	})
end

local function record_scheduled(filepath, line_text)
	local state = load_state()
	if not state[filepath] then
		state[filepath] = {}
	end
	-- avoid duplicates
	for _, existing in ipairs(state[filepath]) do
		if existing == line_text then
			return
		end
	end
	table.insert(state[filepath], line_text)
	save_state(state)
end

function M.setup(opts)
	opts = opts or {}
	local calendar_name = opts.calendar_name or "Calendar"
	local keymap = opts.keymap or "<leader>mc"

	vim.api.nvim_create_user_command("MarkdownCal", function(args)
		local start_line = args.range == 0 and vim.fn.line(".") or args.line1
		local end_line = args.range == 0 and vim.fn.line(".") or args.line2
		local buf = vim.api.nvim_get_current_buf()
		local filepath = vim.api.nvim_buf_get_name(buf)
		local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

		for i, line in ipairs(lines) do
			local event, err = M.calendar.parse_line(line)
			if not event then
				vim.notify(err, vim.log.levels.ERROR)
			else
				local ok, create_err = M.calendar.create_event(event, calendar_name)
				if ok then
					mark_line(buf, start_line + i - 1)
					record_scheduled(filepath, line)
					vim.notify(
						string.format(
							"Created: %s on %s %d:%02d-%d:%02d",
							event.title,
							event.date,
							event.start_time.hour,
							event.start_time.min,
							event.end_time.hour,
							event.end_time.min
						),
						vim.log.levels.INFO
					)
				else
					vim.notify(create_err, vim.log.levels.ERROR)
				end
			end
		end
	end, { range = true, desc = "Create calendar event from current line" })

	vim.api.nvim_create_user_command("MarkdownCalDelete", function(args)
		local line_num = args.range == 0 and vim.fn.line(".") or args.line1
		local buf = vim.api.nvim_get_current_buf()
		local filepath = vim.api.nvim_buf_get_name(buf)
		local line = vim.api.nvim_buf_get_lines(buf, line_num - 1, line_num, false)[1]

		local event, err = M.calendar.parse_line(line)
		if not event then
			vim.notify(err, vim.log.levels.ERROR)
			return
		end

		local ok, del_err = M.calendar.delete_event(event, calendar_name)
		if ok then
			unmark_line(buf, line_num)
			remove_scheduled(filepath, line)
			vim.notify("Deleted: " .. event.title, vim.log.levels.INFO)
		else
			vim.notify(del_err, vim.log.levels.ERROR)
		end
	end, { range = true, desc = "Delete calendar event from current line" })

	vim.api.nvim_create_autocmd("FileType", {
		pattern = { "markdown", "norg" },
		callback = function(args)
			vim.keymap.set("n", keymap, "<cmd>MarkdownCal<cr>", { buffer = args.buf, desc = "Create calendar event" })
			vim.keymap.set("v", keymap, ":MarkdownCal<cr>", { buffer = args.buf, desc = "Create calendar event" })
			vim.keymap.set("n", "<leader>md", "<cmd>MarkdownCalDelete<cr>", { buffer = args.buf, desc = "Delete calendar event" })
			-- restore marks for previously scheduled lines
			local filepath = vim.api.nvim_buf_get_name(args.buf)
			if filepath ~= "" then
				restore_marks(args.buf, filepath)
			end
		end,
	})
end

return M
