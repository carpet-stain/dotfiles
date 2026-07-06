# Changelog

All notable changes to this project, generated from Conventional Commits.
## [1.0.0] - 2026-07-06

### Features

- Add Zellij alongside tmux ([#47](https://github.com/carpet-stain/dotfiles/pull/47))
- *(zellij)* Show contextual keybind hints in the status bar ([#49](https://github.com/carpet-stain/dotfiles/pull/49))
- *(zsh)* Auto-start zellij instead of tmux ([#53](https://github.com/carpet-stain/dotfiles/pull/53))
- *(zellij)* [**breaking**] Complete migration from tmux to zellij ([#54](https://github.com/carpet-stain/dotfiles/pull/54))
- *(zellij)* Mode-aware status bar, tab badges, default session name ([#55](https://github.com/carpet-stain/dotfiles/pull/55))

### Bug Fixes

- *(macos)* Pre-grant zjstatus-hints permissions ([#50](https://github.com/carpet-stain/dotfiles/pull/50))
- *(zellij)* Pin zjstatus, quote its booleans, pre-grant permissions ([#51](https://github.com/carpet-stain/dotfiles/pull/51))
- *(zsh)* Fzf ctrl-e leak, PATH glob safety, small alias cleanup ([#56](https://github.com/carpet-stain/dotfiles/pull/56))

### Revert

- *(zellij)* Remove zjstatus-hints ([#52](https://github.com/carpet-stain/dotfiles/pull/52))

### Chore

- *(zsh)* Disable tmux auto-start for zellij testing ([#48](https://github.com/carpet-stain/dotfiles/pull/48))

## [0.3.1] - 2026-07-05

### Features

- *(theme)* Add catppuccin/eza, document ls_colors regeneration ([#43](https://github.com/carpet-stain/dotfiles/pull/43))

### Bug Fixes

- *(zsh)* Remove dead HISTTIMEFORMAT setting ([#45](https://github.com/carpet-stain/dotfiles/pull/45))

### Refactor

- *(zsh)* Remove cursor-shape widgets ([#44](https://github.com/carpet-stain/dotfiles/pull/44))

## [0.3.0] - 2026-07-05

### Features

- *(zsh)* Generate dua/doggo completions on deploy ([#35](https://github.com/carpet-stain/dotfiles/pull/35))
- *(macos)* Add hyperfine and jaq ([#39](https://github.com/carpet-stain/dotfiles/pull/39))

### Bug Fixes

- *(macos)* Disable ghostty auto palette generation
- *(macos)* Update stale curlrc user-agent ([#38](https://github.com/carpet-stain/dotfiles/pull/38))
- *(macos)* Make deploy.zsh idempotent and fix install_brewfile ([#40](https://github.com/carpet-stain/dotfiles/pull/40))

### Documentation

- *(zsh)* Document zsh-autopair rationale ([#37](https://github.com/carpet-stain/dotfiles/pull/37))

### Performance

- *(zsh)* Stop re-running fast-theme every shell startup ([#33](https://github.com/carpet-stain/dotfiles/pull/33))
- *(zsh)* Defer forgit and fzf-tab-source loading ([#36](https://github.com/carpet-stain/dotfiles/pull/36))

### Styling

- *(zsh)* Trim over-explained comments in widgets.zsh ([#34](https://github.com/carpet-stain/dotfiles/pull/34))

### Chore

- Seed repo-watch state after manual preview run ([#29](https://github.com/carpet-stain/dotfiles/pull/29))
- *(macos)* Reconcile Brewfile with actual installed casks ([#30](https://github.com/carpet-stain/dotfiles/pull/30))
- *(git)* Add submodule diff and rebase/branch settings
- *(macos)* Track claude-code, mullvad-vpn; drop proton-mail-bridge ([#32](https://github.com/carpet-stain/dotfiles/pull/32))

## [0.2.0] - 2026-07-05

### Documentation

- *(git)* Refine workflow policy ([#7](https://github.com/carpet-stain/dotfiles/pull/7))
- *(git)* Drop AI attribution from commit policy ([#14](https://github.com/carpet-stain/dotfiles/pull/14))

### Build

- Add git-cliff for changelog generation ([#16](https://github.com/carpet-stain/dotfiles/pull/16))

### CI

- Add zsh syntax-check workflow ([#13](https://github.com/carpet-stain/dotfiles/pull/13))

### Chore

- *(git)* Use carpet-stain commit identity ([#17](https://github.com/carpet-stain/dotfiles/pull/17))

## [0.1.1] - 2026-07-05

### Bug Fixes

- *(zsh)* Restore _sesh-sessions fpath function
- *(macos)* Use correct Ghostty theme name
- *(macos)* Install ghostty terminfo on deploy

### Styling

- *(macos)* Drop alacritty references from ghostty config

## [0.1.0] - 2026-07-05

### Features

- *(macos)* Migrate Alacritty to Ghostty ([#5](https://github.com/carpet-stain/dotfiles/pull/5))

