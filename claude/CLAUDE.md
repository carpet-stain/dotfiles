<!-- GLOBAL MEMORY — auto-loaded by Claude Code in every project.
     Deployed to $CLAUDE_CONFIG_DIR ($XDG_CONFIG_HOME/claude) via symlink; the
     source of truth is claude/CLAUDE.md in the dotfiles repo.
     This file only wires the layers; content lives in the fragments. -->

# Agent Configuration — Layer Loader

These layers apply to every project UNLESS a layer's own applicability guard excludes
this repo, OR the repo states it owns a more concrete version (in which case the repo's
own docs win). Each fragment carries its own APPLY guard at the top — evaluate it against
the current repo before applying the layer.

@~/.config/claude/fragments/philosophy.md
@~/.config/claude/fragments/go.md
@~/.config/claude/fragments/github.md

<!-- Machine-private layers (work/internal tooling) — gitignored, never committed.
     Present only on machines that need them; on a fresh clone the file is absent and
     Claude Code simply skips the missing import. See claude/README.md § Private fragments. -->
@~/.config/claude/fragments/local.md
