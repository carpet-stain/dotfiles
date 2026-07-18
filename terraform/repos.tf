# Config-as-data: routine changes happen here, not in main.tf's resources.
# One entry per managed repo; the canonical label set applies to every
# managed repo. Governance invariants (rebase-merge only, branch cleanup)
# are fixed in main.tf, not per-repo data — see ADR-0011/ADR-0022.

locals {
  repos = {
    dotfiles = {
      description      = "Personal configuration for zsh, NeoVim, ZelliJ and other tools"
      visibility       = "public"
      has_issues       = true
      has_projects     = true
      has_wiki         = false
      has_discussions  = false
      allow_auto_merge = true
      topics = [
        "configuration-management",
        "dotfiles",
        "dotfiles-linux",
        "dotfiles-macos",
        "dotfiles-manager",
        "ghostty",
        "linux",
        "lua",
        "macos",
        "neovim",
        "zellij",
        "zsh",
      ]
    }

    infra = {
      description      = "GitHub account governance as code — repos, labels, rulesets (OpenTofu)"
      visibility       = "public"
      has_issues       = true
      has_projects     = false
      has_wiki         = false
      has_discussions  = false
      allow_auto_merge = true
      topics = [
        "opentofu",
        "infrastructure-as-code",
        "repos-as-code",
      ]
    }
  }

  labels = {
    "agent-ready"         = { color = "2EA043", description = "Mechanical + verifiable; an autonomous agent can implement it without human judgment" }
    "architecture"        = { color = "1D76DB", description = "Architecturally significant — requires an ADR" }
    "blocked"             = { color = "000000", description = "Not actionable until a dependency clears (reason in a comment / native blocked-by)" }
    "bug"                 = { color = "d73a4a", description = "Something isn't working" }
    "documentation"       = { color = "0075ca", description = "Improvements or additions to documentation" }
    "duplicate"           = { color = "cfd3d7", description = "This issue or pull request already exists" }
    "enhancement"         = { color = "a2eeef", description = "New feature or request" }
    "epic"                = { color = "5319E7", description = "Large multi-part effort" }
    "good first issue"    = { color = "7057ff", description = "Good for newcomers" }
    "priority: high"      = { color = "B60205", description = "Groom/act on soon" }
    "priority: low"       = { color = "C5DEF5", description = "Someday / low urgency" }
    "priority: medium"    = { color = "FBCA04", description = "Normal queue" }
    "release-watch"       = { color = "0E8A16", description = "Flagged by the automated dependency release watcher" }
    "spike"               = { color = "0E8A16", description = "Time-boxed research/decision" }
    "theme: agent-config" = { color = "006B75", description = "Claude agent rules, skills, and AGENTS.md" }
    "theme: credentials"  = { color = "BF8700", description = "Token/credential scoping, storage, and loading" }
    "theme: testing"      = { color = "1D76DB", description = "CI, e2e, and local workflow-run infrastructure" }
    "theme: tool-review"  = { color = "8250DF", description = "Evaluate modern tool/plugin replacements" }
    "theme: xdg-hygiene"  = { color = "D93F0B", description = "$HOME cleanliness / XDG compliance" }
    "upstream-review"     = { color = "5319E7", description = "Ideas from the z0rc/dotfiles fork worth considering" }
    "wontfix"             = { color = "ffffff", description = "This will not be worked on" }
  }
}
