package = "py_lsp"
version = "0.0.1"
specification_version = "0.1.0"
source = "git://github.com/HallerPatrick/py_lsp.nvim",
description = {
   summary = "Helper tool for working with python virtulenvs and LSP",
   detailed = [[
      py_lsp.nvim automatically recognizes venvs (with different strategies) and injects them into the LSP client,
      which allows for autocompletion and linting based on a specific venv
   ]],
   homepage = "git://github.com/HallerPatrick/py_lsp.nvim", 
   license = "" 
}
dependencies = {
   neovim = {
      version = ">= 0.6.1",
      source = "git://github.com/neovim/neovim.git"
   }
}

