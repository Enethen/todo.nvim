local M = {}

local state = {
	first_time = true,
	buf = nil,
	win = nil,
	bg_buf = nil,
	bg_win = nil,
}

M._log = function(message)
	if M.config.development_logs == true then
		vim.notify("[Todo.nvim Dev] " .. message, vim.log.levels.INFO)
	end
end

M._default_name = function()
	return "TodoList_" .. os.date("%y-%m-%d_%H-%M")
end

---@class TodoNvim.Config
---@field disable_diagnostics boolean
---@field document_name string | fun(): string
---@field save_path string
---@field buffer_listed boolean
---@field development_logs boolean
---@field width number
---@field height number
---@field vertical_padding number
---@field horizontal_padding number
---@field border string
---@field style string
---@field default_text fun(): string[]
local defaults = {
	disable_diagnostics = true, -- disables diagnostics of markdown LSP/Linters
	document_name = M._default_name, -- can be either a string or a function
	save_path = "todo-lists/", -- Path to the saving folder, relative to the CWD
	buffer_listed = true, -- should the Todo-list buffer be listed? see :h buflisted
	development_logs = false,
	width = 0.35, -- Width of the Window (percentage of the screen)
	height = 0.8, -- Height of the Window (percentage of the screen)
	vertical_padding = 3, -- Amount of padded lines (Vertical)
	horizontal_padding = 6, -- Amount of padded characters (Horizontal)
	border = "rounded", -- Border style, see h: nvim_open_win
	style = "minimal", -- Style of the window, see h: nvim_open_win
	default_text = function() -- The default text upon opening the window for the first time
		local lines = {
			"# TODO List",
			"",
			"- [ ] Item1",
		}
		return lines
	end,
}

---@type TodoNvim.Config
M.defaults = vim.deepcopy(defaults)

---@type TodoNvim.Config
M.config = vim.deepcopy(defaults)

local function draw_windows()
	local width = math.floor(vim.o.columns * M.config.width)
	local height = math.floor(vim.o.lines * M.config.height)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	state.bg_win = vim.api.nvim_open_win(state.bg_buf, false, {
		relative = "editor",
		width = width,
		height = height,
		border = M.config.border,
		style = M.config.style,
		row = row,
		col = col,
	})

	local Vpadding = M.config.vertical_padding
	local Hpadding = M.config.horizontal_padding
	state.win = vim.api.nvim_open_win(state.buf, true, {
		relative = "editor",
		width = width - (Hpadding * 2),
		height = height - (Vpadding * 2),
		row = row + Vpadding,
		col = col + Hpadding,
		style = M.config.style,
		border = "none",
	})

	vim.wo[state.win].signcolumn = "no" -- Avoid showing lsp symbols (warnings)
	vim.wo[state.win].wrap = true
	vim.wo[state.win].spell = true
end

function M.toggle()
	if state.win and state.buf and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
		vim.api.nvim_win_close(state.bg_win, true)
		state.win = nil
		state.bg_win = nil
		return
	end

	if not state.buf then
		state.first_time = true
		M._create_buffers()
	end

	draw_windows()

	if state.first_time then
		-- Go to end of buffer and delete last empty line then go into insert mode
		vim.api.nvim_feedkeys("GVx$", "n", true)
		state.first_time = false
	end
end

function M.toggle_checkbox()
	local row = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
	if not line then
		return
	end

	if line:find("%- %[ %] ") then
		line = line:gsub("%- %[ %] ", "- [X] ")
	elseif line:find("%- %[[X|x]%] ") then
		line = line:gsub("%- %[[X|x]%] ", "- [ ] ")
	end
	vim.api.nvim_buf_set_lines(0, row - 1, row, false, { line })
end

---@param opts TodoNvim.Config
function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_extend("force", vim.deepcopy(defaults), opts)

	vim.keymap.set("n", "<leader>t", M.toggle, { desc = "Toggle Scratch Todo Window" })
	vim.api.nvim_create_user_command("ScratchTodo", M.toggle, {})

	vim.api.nvim_create_autocmd("VimResized", {
		group = vim.api.nvim_create_augroup("Todo.nvim-resized", {}),
		callback = function()
			if state.win == nil or not vim.api.nvim_win_is_valid(state.win) then
				return
			end
			M.toggle()
			M.toggle()
		end,
	})

	M._log("M.setup(opts) has been executed!")
end

M._create_buffers = function()
	state.bg_buf = vim.api.nvim_create_buf(false, true) -- [listed], [scratch]
	state.buf = vim.api.nvim_create_buf(M.config.buffer_listed, false)

	local config_name_type = type(M.config.document_name)
	local name = config_name_type == "function" and M.config.document_name()
		or config_name_type == "string" and M.config.document_name
		or M._default_name()

	local path = M.config.save_path or ""
	if not path.match(path, "/$") and path ~= "" then
		path = path .. "/"
	end
	name = path .. name .. ".md"

	if M.config.disable_diagnostics == true then
		M._log("disable_diagnostics = true")
		vim.diagnostic.enable(false, { bufnr = state.buf })
	end

	vim.api.nvim_buf_set_name(state.buf, name)
	vim.b[state.buf]._is_todo_buffer = true -- Set custom data to recognize this buffer later
	vim.bo[state.buf].shiftwidth = 2 -- Set indent width
	vim.bo[state.buf].tabstop = 2 -- How many spaces a tab counts for
	vim.bo[state.buf].expandtab = true -- Use spaces instead of tabs
	vim.bo[state.buf].filetype = "markdown"
	-- vim.bo[state.buf].buftype = "nofile"
	vim.bo[state.buf].bufhidden = M.config.buffer_listed and nil or "hide"
	vim.bo[state.buf].swapfile = false

	vim.api.nvim_set_option_value("modifiable", true, { buf = state.buf })

	local lines = M.config.default_text()
	vim.api.nvim_buf_set_lines(state.buf, 0, 0, false, lines)

	M._set_buffer_keymaps(state.buf)
end

M._set_buffer_keymaps = function(bufnr)
	local keymap_opts = { buffer = bufnr, silent = true }
	-- "q" to close floating window
	vim.keymap.set("n", "q", M.toggle, keymap_opts)
	-- vim.keymap.set("n", "<Esc>", M.toggle, keymap_opts) -- This does not feel good
	vim.keymap.set("n", "<C-c>", M.toggle, keymap_opts)

	-- C-I does nothing,C-O closes the buffer instead of jumping
	vim.keymap.set("n", "<C-o>", M.toggle, keymap_opts)
	vim.keymap.set("n", "<C-i>", "<Nop>", keymap_opts)

	-- Enter to toggle the todo
	vim.keymap.set("n", "<CR>", M.toggle_checkbox, keymap_opts)

	-- Tab and Shift-Tab to indent lines
	vim.keymap.set("n", "<Tab>", "V><Esc>", keymap_opts)
	vim.keymap.set("n", "<S-Tab>", "V<<Esc>", keymap_opts)
	vim.keymap.set("x", "<Tab>", ">gv", keymap_opts)
	vim.keymap.set("x", "<S-Tab>", "<gv", keymap_opts)

	-- Auto-insert '- [ ] ' on new lines
	vim.keymap.set("i", "<Enter>", "<Enter>- [ ] ", keymap_opts)
	vim.keymap.set("n", "o", "o- [ ] ", keymap_opts)
	-- vim.keymap.set("n", "O", "O- [ ] ", keymap_opts) -- This does not feel good
end

return M
