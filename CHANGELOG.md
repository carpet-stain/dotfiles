# Changelog

All notable changes to this project, generated from Conventional Commits.
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

