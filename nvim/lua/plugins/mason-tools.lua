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

-- Each dev-LSP tool: Mason's own package name, the lspconfig server name
-- registered for it (nil if it isn't an LSP server — markdown-toc is a
-- conform.nvim formatter, no `mason = false` equivalent applies to it), and
-- the actual binary `executable()` checks for on PATH (not always the same
-- as the Mason package name).
local dev_tools = {
  { mason = "pyright", server = "pyright", bin = "pyright-langserver" },
  { mason = "ruff", server = "ruff", bin = "ruff" },
  { mason = "gopls", server = "gopls", bin = "gopls" },
  { mason = "json-lsp", server = "jsonls", bin = "vscode-json-language-server" },
  { mason = "yaml-language-server", server = "yamlls", bin = "yaml-language-server" },
  { mason = "marksman", server = "marksman", bin = "marksman" },
  { mason = "markdown-toc", server = nil, bin = "markdown-toc" },
  -- lua_ls is registered by LazyVim core (lazyvim.plugins.lsp.init), not a
  -- lang extra — same treatment applies regardless of where a server gets
  -- registered. selene/stylua aren't LSP servers (nvim-lint/conform call
  -- them directly by binary name, see lang-lua.lua) so `server = nil`, same
  -- as markdown-toc: Mason can still own installing them, there's just no
  -- `mason = false` toggle to flip for a non-LSP tool.
  { mason = "lua-language-server", server = "lua_ls", bin = "lua-language-server" },
  { mason = "selene", server = nil, bin = "selene" },
  { mason = "stylua", server = nil, bin = "stylua" },
  -- Go's other lang.go-extra tools: none of these are LSP servers either —
  -- goimports/gofumpt are conform.nvim formatters, golangci-lint is an
  -- nvim-lint linter, gomodifytags/impl are none-ls code actions, delve
  -- (binary `dlv`) is nvim-dap's debugger — all invoked directly by binary
  -- name, same `server = nil` treatment as selene/stylua/markdown-toc.
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
      -- Strip any dev_tools entry regardless of which spec added it (this
      -- file, or an extra's own ensure_installed), then re-add only the
      -- ones not already available on PATH — Mason owns exactly the gap.
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
          -- Keep the LSP registered (nvim-lspconfig's default `cmd` is just
          -- the bare binary name, so it still attaches via PATH) but stop
          -- mason-lspconfig from auto-installing/managing a second copy.
          opts.servers[tool.server] = opts.servers[tool.server] or {}
          opts.servers[tool.server].mason = false
        end
      end
    end,
  },
}
