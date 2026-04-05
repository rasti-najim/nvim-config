local M = {}

M.calendar = require("markdown-tools.calendar")

function M.setup(opts)
	opts = opts or {}
	local calendar_name = opts.calendar_name or "Calendar"
	local keymap = opts.keymap or "<leader>mc"

	vim.api.nvim_create_user_command("MarkdownCal", function(args)
		local start_line = args.range == 0 and vim.fn.line(".") or args.line1
		local end_line = args.range == 0 and vim.fn.line(".") or args.line2
		local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

		for _, line in ipairs(lines) do
			local event, err = M.calendar.parse_line(line)
			if not event then
				vim.notify(err, vim.log.levels.ERROR)
			else
				local ok, create_err = M.calendar.create_event(event, calendar_name)
				if ok then
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

	vim.keymap.set("n", keymap, "<cmd>MarkdownCal<cr>", { desc = "Create calendar event" })
	vim.keymap.set("v", keymap, ":MarkdownCal<cr>", { desc = "Create calendar event" })
end

return M
