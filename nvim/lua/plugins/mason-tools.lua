-- LazyVim's official lang extras (python, go, json, yaml, markdown) declare
-- their LSP servers via nvim-lspconfig's `servers` table, which
-- mason-lspconfig.nvim uses to build its own, independent auto-install list
-- (one entry per registered server whose `mason` field isn't `false`) — a
-- second install path that doesn't go through this file's `ensure_installed`
-- at all. Some of those same extras also add straight to mason.nvim's
-- `ensure_installed` directly (markdown's extra lists "markdown-toc" itself).
-- Gating both plugin blocks below closes both paths for the tools below, not
-- just this file's own contribution.
--
-- Prefer a system-installed copy over Mason's own, per tool, rather than
-- gating on macOS vs. Linux (#127/#364's premise reversal: a Linux dev box
-- isn't just for editing this repo — it does general development work too,
-- so it may well have `gopls`/`pyright`/etc. already on PATH via `go
-- install`/`pipx`/`npm -g`/apt, same as macOS via Homebrew). Where the
-- binary is already resolvable, skip Mason entirely for it; where it isn't,
-- Mason installs and manages it as before — on either platform. This also
-- sidesteps Mason's own PATH-prepend: once Mason has installed a copy, its
-- bin dir wins over a same-named system binary regardless of these gates,
-- so the guard has to be "don't let Mason install it in the first place"
-- (`:MasonUninstall <tool>` once, by hand, undoes an existing install this
-- didn't prevent).
--
-- The explicit `ensure_installed` list (for tools the check below decides
-- Mason should still own) is still what makes a fresh machine's install
-- deterministic: mason-lspconfig's own auto-install is skipped entirely in
-- headless sessions (its own `is_headless` guard checks
-- `#vim.api.nvim_list_uis() == 0`, true for any `nvim --headless` run,
-- buffer loaded or not) — confirmed via ~/.local/state/nvim/mason.log during
-- a headless `deploy.zsh` bootstrap: no install was even attempted.

-- Per tool: Mason's package name, the lspconfig server name (nil when it isn't an
-- LSP server), and the binary `executable()` checks for — not always the same name.
local dev_tools = {
  { mason = "pyright", server = "pyright", bin = "pyright-langserver" },
  { mason = "ruff", server = "ruff", bin = "ruff" },
  { mason = "gopls", server = "gopls", bin = "gopls" },
  { mason = "json-lsp", server = "jsonls", bin = "vscode-json-language-server" },
  { mason = "yaml-language-server", server = "yamlls", bin = "yaml-language-server" },
  { mason = "marksman", server = "marksman", bin = "marksman" },
  { mason = "markdown-toc", server = nil, bin = "markdown-toc" },
  -- lua_ls is registered by LazyVim core, not a lang extra; same treatment either way.
  -- selene/stylua aren't LSP servers (see lang-lua.lua), so `server = nil`.
  { mason = "lua-language-server", server = "lua_ls", bin = "lua-language-server" },
  { mason = "selene", server = nil, bin = "selene" },
  { mason = "stylua", server = nil, bin = "stylua" },
  -- lang.go's other tools — formatters, a linter, code actions, delve (binary `dlv`).
  -- None are LSP servers, so `server = nil` like selene/stylua.
  { mason = "goimports", server = nil, bin = "goimports" },
  { mason = "gofumpt", server = nil, bin = "gofumpt" },
  { mason = "golangci-lint", server = nil, bin = "golangci-lint" },
  { mason = "gomodifytags", server = nil, bin = "gomodifytags" },
  { mason = "impl", server = nil, bin = "impl" },
  { mason = "delve", server = nil, bin = "dlv" },
}

local function on_path(tool)
  return vim.fn.executable(tool.bin) == 1
end

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      -- Strip every dev_tools entry regardless of which spec added it, then re-add
      -- only those not already on PATH — Mason owns exactly the gap.
      local names = vim.tbl_map(function(t)
        return t.mason
      end, dev_tools)
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return not vim.tbl_contains(names, tool)
      end, opts.ensure_installed or {})
      for _, tool in ipairs(dev_tools) do
        if not on_path(tool) then
          table.insert(opts.ensure_installed, tool.mason)
        end
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      for _, tool in ipairs(dev_tools) do
        if tool.server and on_path(tool) then
          -- Keeps the LSP registered (default `cmd` is the bare binary, so it attaches
          -- via PATH) but stops mason-lspconfig managing a second copy.
          opts.servers[tool.server] = opts.servers[tool.server] or {}
          opts.servers[tool.server].mason = false
        end
      end
    end,
  },
}
