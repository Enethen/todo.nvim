vim.api.nvim_create_user_command("TodoToggle", function()
	require("todo").toggle()
end, { desc = "Toggles the Todo-list" })

vim.api.nvim_create_user_command("TodoSelectCurrentBuffer", function()
	require("todo").select_current_buffer()
end, { desc = "Selects the current Buffer as the Todo-list" })

vim.api.nvim_create_user_command("TodoToggleCheckbox", function()
	require("todo").toggle_checkbox()
end, { desc = "Toggles the markdown checkbox in current line" })
