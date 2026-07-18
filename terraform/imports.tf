# One-time adoption of the already-existing resources (ADR-0022 §4).
# Import blocks are no-ops once state holds the resource, so these stay —
# they double as the recipe for adopting the next repo into the map.

import {
  for_each = local.repos
  to       = github_repository.this[each.key]
  id       = each.key
}

import {
  for_each = local.labels
  to       = github_issue_label.this[each.key]
  id       = "dotfiles:${each.key}"
}

import {
  to = github_repository_ruleset.protect_main
  id = "dotfiles:18503611"
}
