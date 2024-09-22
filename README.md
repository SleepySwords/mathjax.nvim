# Mathjax.nvim

Maths in my neovim!?!

https://github.com/user-attachments/assets/3320d021-8239-45ab-9390-d152378ddcde

# Motivation

To be able to specify math notation using Latex like syntax within two `$$`
inside a markdown file. This then renders your math symbols using Mathjax
after running the lua function `render_latex`, directly into your terminal
if they support some sort of image rendering (such as Kitty).

This plugin does not currently support inline latex, only Latex blocks are
supported as of right now.

# Usage


Inside your markdown, you can specify Latex blocks using the two `$$`
syntax like so
```markdown
$$
\text{Hello world}
y = mx + c
$$
```

## Using the lua call

Run the function `require('mathjax').render_latex()` to render any math blocks
using mathjax.

You can either bind this to a keybind or set it as an autocommand to be able to
run it on save:
```lua
vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = "*.md",
    callback = require("mathjax").render_latex
})
```

## Using the command

Alternatively, you could run the command `:Mathjax` to do the same thing
(options must be specified in the `setup` function in this case).

# Dependencies

- Node
    - Node is required to be installed to be able to run the Mathjax script for
      rendering.
    - You will also need a package manager to install the required
      packages (whether it is yarn, npm, etc...)
- image.nvim
- Treesitter
    - You must have the Latex, markdown and markdown inline parser installed.
    - This can be installed via `:TSInstall latex markdown markdown_inline`

# Installation

Use a package manager to install `mathjax.nvim`. Be sure to follow the
installation instructions of [image.nvim](https://github.com/3rd/image.nvim) as
that requires the magick luarocks to be installed to be able to work.

## via Lazy using yarn
```lua
{
    'SleepySwords/mathjax.nvim',
    -- Replace this with whatever node package manager you use.
    build = 'cd mathjax && yarn install',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      '3rd/image.nvim'
    },
    opts = {}
}
```

# Options

Options can be passed into either by the `setup` function, which sets the options
globally, or the `render_latex` function which sets them locally. Note: passing
in options to either of these functions is optional.

## Option table

| Property | Type    | Description                                                                                           |
|----------|---------|-------------------------------------------------------------------------------------------------------|
| color    | string? | Set the color of the Latex text, this can be in the form of a name or hex, such as `red` or `#ffffbb` |

# Latex options

Options can be specified in Latex using comments, they take the form of `%
Property: Value`

## Latex option table

| Property | Type    | Description                                                                                            |
|----------|---------|------------------------------------------------------------------------------------------------------- |
| Lines    | integer? | Specifies the amount of lines this particular latex block should take, note: this may not always work |

## Example

```markdown
$$ % Lines: 1
\displaylines{
    \text{Hello world}
    y = mx + c
}
$$
```

# Credit
This was inspired by the Neorg Latex Renderer
