# ✅ Todo.nvim

**Todo.nvim** helps you keep focused on what matters by quickly toggling and typing TODOs inside a togglable scratch buffer.

## ✨ Features

- [x] **Tick**: Press `<CR>` when in Normal mode to tick/untick the current line's todo
- [x] **Easy Checkboxes**: `<CR>`(i), `o`(n) and `O`(n) will all prepend the `- [ ]` prefix automatically
- [x] **Toggle**: Press `<leader>t` to open/close the todo-list
- [x] **Exit**: Press `q`, `<C-o>`, `<C-c>` or `<Esc>` to close the floating window
- [x] **Indent**: Press `<Tab>`(n) and `<S-Tab>`(n) to easily indent the todos
- [x] **Layout**: Nice looking floating window with padding
- [x] **Resize**: Window automatically resize along with Neovim

## ⚡️ Requirements

- Neovim >= 0.10.0
- for better markdown rendering _(optional)_:
  - [render-markdown](MeanderingProgrammer/render-markdown.nvim)

## 📦 Installation

Install the plugin using your favorite package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "Enethen/todo.nvim",
  event = "VeryLazy",
  -- opts = { }
}
```

## ⚙️ Configuration

Not yet implemented. Please let me know if you'd like anything to be configurable!

## TODOs Features

- [ ] Add config `opts` to `require("todo").setup()`
- [ ] Saving todo lists
  - [ ] Configurable `global`, `project` and `scratch-only` options for saving behaviours.
  - [ ] Easy todo-lists retrieving via fuzzy pickers (telescope, fzf or Snacks)

## Acknoledgement

This is my first Neovim plugin, which I made thanks to [Teej](https://www.youtube.com/@teej_dv)'s [tutorials](https://www.youtube.com/watch?v=VGid4aN25iI&list=PLep05UYkc6wTyBe7kPjQFWVXTlhKeQejM&index=19) and following [Folke](https://github.com/folke)'s awesome READMEs formatting 😊

The idea came from this [video](https://www.youtube.com/watch?v=LaIa1tQFOSY) from Coding With Sphere.
Since I did not find such a plugin, I decided to give it a shot!
