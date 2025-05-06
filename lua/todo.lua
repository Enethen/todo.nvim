local M = {}

local first_time = true
local buf, win, bg_buf, bg_win

local function draw_windows(config)
	config = config or {}
	local width = config.width or math.floor(vim.o.columns * 0.3)
	local height = config.height or math.floor(vim.o.lines * 0.8)
	local row = config.row or math.floor((vim.o.lines - height) / 2)
	local col = config.col or math.floor((vim.o.columns - width) / 2)

	bg_win = vim.api.nvim_open_win(bg_buf, false, {
		relative = "editor",
		width = width,
		height = height,
		border = "rounded",
		style = "minimal",
		row = row,
		col = col,
	})

	local Vpadding = 3
	local Hpadding = 6
	win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width - (Hpadding * 2),
		height = height - (Vpadding * 2),
		row = row + Vpadding,
		col = col + Hpadding,
		style = "minimal",
		border = "none",
	})

	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].wrap = true
	vim.wo[win].spell = true

	vim.wo[bg_win].number = false
	vim.wo[bg_win].relativenumber = false
end

function M.toggle()
	if win and buf and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
		vim.api.nvim_win_close(bg_win, true)
		win = nil
		bg_win = nil
		-- buf = nil
		return
	end

	if not buf then
		first_time = true

		bg_buf = vim.api.nvim_create_buf(false, true)
		buf = vim.api.nvim_create_buf(false, true) -- [listed = false], [scratch = true]
		vim.bo[buf].shiftwidth = 2 -- Set indent width
		vim.bo[buf].tabstop = 2 -- How many spaces a tab counts for
		vim.bo[buf].expandtab = true -- Use spaces instead of tabs
		vim.bo[buf].filetype = "markdown"
		vim.bo[buf].buftype = "nofile"
		vim.bo[buf].bufhidden = "hide"
		vim.bo[buf].swapfile = false
		vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
		local lines = {
			"# TODO List",
			"",
			"- [ ] Item1",
		}
		vim.api.nvim_buf_set_lines(buf, 0, 0, false, lines)

		local keymap_opts = { buffer = buf, silent = true }
		-- "q" to close floating window
		vim.keymap.set("n", "q", M.toggle, keymap_opts)
		vim.keymap.set("n", "<Esc>", M.toggle, keymap_opts)
		vim.keymap.set("n", "<C-c>", M.toggle, keymap_opts)

		-- C-I does nothing,C-O closes the buffer instead of jumping
		vim.keymap.set("n", "<C-o>", M.toggle, keymap_opts)
		vim.keymap.set("n", "<C-i>", "<Nop>", keymap_opts)

		-- Enter to toggle the todo
		vim.keymap.set("n", "<CR>", M.toggle_checkbox, keymap_opts)

		-- Tab and Shift-Tab to indent lines
		vim.keymap.set("n", "<Tab>", "V><Esc>", keymap_opts)
		vim.keymap.set("n", "<S-Tab>", "V<<Esc>", keymap_opts)

		-- Auto-insert '- [ ] ' on new lines
		vim.keymap.set("i", "<Enter>", "<Enter>- [ ] ", keymap_opts)
		vim.keymap.set("n", "o", "o- [ ] ", keymap_opts)
		vim.keymap.set("n", "O", "O- [ ] ", keymap_opts)
	end

	draw_windows()

	if first_time then
		-- Go to end of buffer and delete last empty line then go into insert mode
		vim.api.nvim_feedkeys("GVxA", "n", true)
		first_time = false
	end
end

function M.toggle_checkbox()
	local row = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
	if not line then
		return
	end

	if line:find("%- %[ %] ") then
		line = line:gsub("%- %[ %] ", "- [x] ")
	elseif line:find("%- %[x%] ") then
		line = line:gsub("%- %[x%] ", "- [ ] ")
	end
	vim.api.nvim_buf_set_lines(0, row - 1, row, false, { line })
end

function M.setup()
	vim.keymap.set("n", "<leader>t", M.toggle, { desc = "Toggle Scratch Todo Window" })
	vim.api.nvim_create_user_command("ScratchTodo", M.toggle, {})

	vim.api.nvim_create_autocmd("VimResized", {
		group = vim.api.nvim_create_augroup("Todo.nvim-resized", {}),
		callback = function()
			if not vim.api.nvim_win_is_valid(win) or win == nil then
				return
			end
			M.toggle()
			M.toggle()
		end,
	})
end

return M
