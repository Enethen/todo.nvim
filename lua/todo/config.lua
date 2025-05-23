local M = {}

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
M.defaults = {
	disable_diagnostics = true, -- disables diagnostics of markdown LSP/Linters
	document_name = M._default_name, -- can be either a string or a function
	save_path = "todo-lists/", -- Path to the saving folder, relative to the CWD
	buffer_listed = true, -- should the Todo-list buffer be listed? see :h buflisted
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
	development_logs = false,
}

return M
