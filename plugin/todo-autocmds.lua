vim.api.nvim_create_user_command("TodoToggle", function()
	require("todo").toggle()
end, { desc = "Toggles the Todo-list" })
