# Mathjax.nvim

Maths in my neovim!?!

You are able to specify math notation using Latex like syntax within two \$\$
inside a markdown file. This then renders your math symbols using Mathjax. 

This plugin also does not currently support inline latex, only Latex blocks are
supported as of right now.


## Usage

Run the command `require('mathjax').render_latex()` renders any math blocks
using mathjax.

You can either bind this to a keybind or set it as an
autocommand like so:
```lua

```


## Dependencies
- Node
    - Node is required to be installed to be able to run the Mathjax script for
      rendering.
    - You will also need a package manager to install the required
      packages (whether it is yarn, npm, etc...)
- image.nvim
- Treesitter
    - You must have the Latex parser installed.
    - This can be installed via `:TSInstall latex`

## Installation

Use a package manager to install `mathjax.nvim`. Be sure to follow the
installation instructions of [image.nvim] as that requires some luarocks to be
installed to be able to work.

### via Lazy using yarn
```lua
{
    'SleepySwords/mathjax.nvim',
    build = 'cd mathjax && yarn install',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      '3rd/image.nvim'
    }
}
```

## Credit
This was inspired by the Neorg Latex Renderer

## Planned
- [ ] Add support for inline latex expressions
- [ ] Allow for asciimath

$$ %% Lines: 5
\begin{align}
x^2 &= 2x + 3 \\
x^2 - 2x + 3 &= 0 \\
(x - 2) (x - 1) &= 0
\end{align}
$$


$$ %% Lines: 3
\begin{align}
  &\text{
    Let $x$ be a vector such that $x = <a, b, c>$
  }
  \\
  &\text{
    It can be seen that $x!!0 = a$
  }
  \\
  &\text{ 
    There is a set such that $X \cup Y$
  }
  \text{hey \huge there \small aef \textbf{awefjoi}}
\end{align}
$$
