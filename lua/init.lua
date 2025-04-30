local M = {}

local buf, win

function M.toggle()
  if win and buf and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
    win = nil
    -- buf = nil
    return
  end

  if not buf then
    buf = vim.api.nvim_create_buf(false, true) -- [listed = false], [scratch = true]
    vim.bo[buf].shiftwidth = 2 -- Set indent width
    vim.bo[buf].tabstop = 2 -- How many spaces a tab counts for
    vim.bo[buf].expandtab = true -- Use spaces instead of tabs
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  end

  local width = math.floor(vim.o.columns * 0.5)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].wrap = true
  vim.wo[win].spell = true

  vim.keymap.set("n", "q", M.toggle, { buffer = buf, silent = true })
  vim.keymap.set("n", "<CR>", M.toggle_checkbox, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Tab>", "V><Esc>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<S-Tab>", "V<<Esc>", { buffer = buf, silent = true })

  -- Auto-insert '- [ ] ' on new lines
  local lock = true
  vim.api.nvim_create_autocmd("TextChangedI", {
    buffer = buf,
    callback = function()
      if lock then
        lock = false
        return
      end
      local line = vim.api.nvim_get_current_line()
      local indent = line:match("^%s*")
      local prefix = "- [ ] "
      local avoid = line:match("^%s*%-%s%[.%]%s$")
      if avoid ~= nil or line == "" or #indent > 0 then
        vim.api.nvim_set_current_line(indent .. prefix .. line)
        local esc = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)
        vim.api.nvim_feedkeys(esc .. "A", "n", false)
        lock = true
      end
    end,
  })
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

function M.setup(opts)
  vim.keymap.set("n", "<leader>t", M.toggle, { desc = "Toggle Scratch Todo Window" })
  vim.api.nvim_create_user_command("ScratchTodo", M.toggle, {})
end

return M
