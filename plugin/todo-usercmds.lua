local extract_user_command_arguments = function(raw_args)
	return vim.split(raw_args["args"], "(% +)", { trimempty = true })
end

vim.api.nvim_create_user_command("TodoToggle", function()
	require("todo").toggle()
end, { desc = "Toggles the Todo-list" })

vim.api.nvim_create_user_command("TodoSelectCurrentBuffer", function()
	require("todo").select_current_buffer()
end, { desc = "Selects the current Buffer as the Todo-list" })

vim.api.nvim_create_user_command("TodoToggleCheckbox", function()
	require("todo").toggle_checkbox()
end, { desc = "Toggles the markdown checkbox in current line" })

vim.api.nvim_create_user_command("TodoSetWidth", function(raw_args)
	local width = extract_user_command_arguments(raw_args)[1]
	require("todo").set_width(width)
end, { desc = "Toggles the markdown checkbox in current line", nargs = 1 })

vim.api.nvim_create_user_command("TodoSetHeight", function(raw_args)
	local height = extract_user_command_arguments(raw_args)[1]
	require("todo").set_height(height)
end, { desc = "Toggles the markdown checkbox in current line", nargs = 1 })
