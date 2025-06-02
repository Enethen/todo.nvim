local M = {}

local state = {
	buf = nil,
	win = nil,
	bg_buf = nil,
	bg_win = nil,
	window_opened = false,
}

M._log = function(message)
	if M.config.development_logs == true then
		vim.notify("[Todo.nvim Dev] " .. message, vim.log.levels.INFO)
	end
end

---@type TodoNvim.Config
M.defaults = vim.deepcopy(require("todo.config").defaults)

---@type TodoNvim.Config
M.config = vim.deepcopy(M.defaults)

local function open_windows()
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
	M._log("bg_win was set to: " .. state.bg_win)

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

	state.window_opened = true
end

function M.close_windows()
	M._log("Closing windows") --: bg_win=" .. tostring(state.bg_win) .. " | win=" .. tostring(state.win))
	if vim.api.nvim_win_is_valid(state.bg_win) then
		vim.api.nvim_win_close(state.bg_win, true)
	end
	if vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end
	-- local ok, error = pcall(vim.api.nvim_win_close, state.bg_win, true)
	-- if not ok then
	-- end
	-- M._log("Error! bg_win=" .. tostring(state.bg_win) .. "\nErrormsg:\n" .. error)
	state.win = nil
	state.bg_win = nil
	state.window_opened = false
end

function M.is_opened()
	local opened = state.window_opened and state.win and state.buf and vim.api.nvim_win_is_valid(state.win) or false
	M._log("Is opened? " .. tostring(opened))
	return opened
end

function M.toggle()
	M._log("M.toggle() : IsOpened being called.")
	if M.is_opened() == true then
		M.close_windows()
		return
	end

	local buffers_just_created = false
	if not state.buf then
		M._create_buffers()
		buffers_just_created = true
	end

	open_windows()

	if buffers_just_created then
		-- Go to end of buffer and delete last empty line
		vim.api.nvim_feedkeys("GVx$", "n", true)
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
	M.config = vim.tbl_extend("force", vim.deepcopy(M.defaults), opts)

	vim.keymap.set("n", "<leader>t", M.toggle, { desc = "Toggle Scratch Todo Window" })

	vim.api.nvim_create_autocmd("VimResized", {
		group = vim.api.nvim_create_augroup("Todo.nvim-resized", {}),
		callback = function()
			M._log("VimResized callback")
			if not M.is_opened() then
				return
			end
			M.toggle()
			M.toggle()
		end,
	})

	-- Auto-close when the window loses focus or navigating to other buffer
	vim.api.nvim_create_autocmd("BufLeave", {
		group = vim.api.nvim_create_augroup("TodoNvim_BufLeave", { clear = true }),
		buffer = state.buf,
		callback = function()
			M._log("BufLeave callback")
			if M.is_opened() then
				M.close_windows()
			end
		end,
	})

	vim.api.nvim_create_autocmd("WinLeave", {
		group = vim.api.nvim_create_augroup("TodoNvim_WinLeave", { clear = true }),
		buffer = state.buf,
		callback = function()
			M._log("WinLeave callback")
			if M.is_opened() then
				M.close_windows()
			end
		end,
	})

	M._log("M.setup(opts) has been executed!")
end

M._create_buffers = function()
	state.buf = vim.api.nvim_create_buf(M.config.buffer_listed, false)

	-- Setting name and path
	local config_name_type = type(M.config.document_name)
	local name = (config_name_type == "function" and M.config.document_name())
		or (config_name_type == "string" and M.config.document_name)
	local path = M.config.save_path or ""
	if not path.match(path, "/$") and path ~= "" then
		path = path .. "/"
	end
	name = path .. name .. ".md"
	vim.api.nvim_buf_set_name(state.buf, name)

	-- Setting default_text
	local lines = M.config.default_text()
	vim.api.nvim_buf_set_lines(state.buf, 0, 0, false, lines)

	M._select_buffer(state.buf)
end

M._select_buffer = function(bufnr)
	-- Make sure to create an empty scratch buffer for the BG if not existing
	if state.bg_buf == nil then
		state.bg_buf = vim.api.nvim_create_buf(false, true) -- [listed], [scratch]
	end

	state.buf = bufnr
	-- Removing diagnostics
	if M.config.disable_diagnostics == true then
		M._log("disable_diagnostics = true")
		vim.diagnostic.enable(false, { bufnr = bufnr })
	end

	vim.bo[bufnr].shiftwidth = 2
	vim.bo[bufnr].tabstop = 2
	vim.bo[bufnr].softtabstop = 2
	vim.bo[bufnr].expandtab = true -- Use spaces instead of tabs
	vim.bo[bufnr].filetype = "markdown"
	vim.bo[bufnr].bufhidden = M.config.buffer_listed and nil or "hide"

	M._set_buffer_keymaps(bufnr)
end

M._set_buffer_keymaps = function(bufnr)
	local keymap_opts = function(desc)
		return { desc = desc, buffer = bufnr, silent = true }
	end
	for _, mapping in ipairs(M.config.mappings) do
		vim.keymap.set(mapping.mode or "n", mapping.lhs, mapping.rhs, keymap_opts(mapping.desc))
		print("keymap: " .. mapping.lhs)
	end
end

M.select_current_buffer = function()
	if M.is_opened() then
		vim.notify("Cannot be executed while the Todo-list is opened.", vim.log.levels.WARN)
	end

	M._select_buffer(vim.api.nvim_get_current_buf())
	M.toggle()
end

local saturate = function(number)
	return math.max(0.2, math.min(1, number))
end
M.set_width = function(width)
	M.config.width = saturate(width or M.config.width)

	if M.is_opened() then
		M.toggle()
		M.toggle()
	end
end

M.set_height = function(height)
	M.config.height = saturate(height or M.config.height)

	if M.is_opened() then
		M.toggle()
		M.toggle()
	end
end

return M
