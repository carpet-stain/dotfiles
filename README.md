# Dotfiles

## License

[WTFPL](COPYING)

## Personal dotfiles

usable both on server and personal workstation -- for graphical stuff check `Brewfile`.
Battle tested on macOS and Arch Linux.

I'm a big fan of [XDG Base Directory
Specification](http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html)
and organize my dotfiles in a way that they don't clutter the `$HOME`. I was
able to reduce files required to be in `$HOME` to single `.zshenv`, everything
else goes under standard XDG paths or launched via aliases. Additionally if you
have root permissions, you can install dotfiles with [zero home
presence](#zero-home-presence).

## Features

- Extensive Zsh [configuration](zsh/rc.d) and [plugins](zsh/plugins):
  - [powerline10k](https://github.com/romkatv/powerlevel10k) prompt stylized
    like [pure](https://github.com/sindresorhus/pure)
  - [additional completions](https://github.com/zsh-users/zsh-completions)
  - [async autosuggestions
    plugin](https://github.com/zsh-users/zsh-autosuggestions)
  - [syntax highlighting
    plugin](https://github.com/zsh-users/zsh-syntax-highlighting)
  - [autopair plugin](https://github.com/hlissner/zsh-autopair)
- Neovim [configuration](nvim/init.lua)
- Tmux [configuration](tmux/tmux.conf) and [plugins](tmux/plugins)
- Other configs:
  - [Git](git/)
- [goenv](https://github.com/syndbg/goenv),
  [nodenv](https://github.com/nodenv/nodenv)

## Installation

Requirements:

- `zsh` 5.1 or newer (async stuff requires recent enough version of zsh)
- `git`

Dotfiles can be installed in any dir, but probably somewhere under `$HOME`.
Personally I use `$HOME/.local/dotfiles`. The installation is pretty simple:

```shell
git clone https://github.com/brianleppez/dotfiles.git "$HOME/.local/dotfiles"
$HOME/.local/dotfiles/deploy.zsh
chsh -s /bin/zsh
```

[Deployment script](macos/deploy.zsh) helps to set up all required symlinks after the
initial clone. Also it adds cron job to pull updates every midnight and serves
as a post-merge git hook, so you don't have to care about updating submodules
after successful pull.

In case of missing python or ruby, they can be installed via pyenv and rbenv
after the deployment.

## Configuration

### Zsh configuration

Keep in mind that Zsh configuration skips every global configuration file
except `/etc/zsh/zshenv`.

The difference is that `env.d` is sourced always while `rc.d` is sourced in interactive session only.

Also `$ZDOTDIR/.zlogin` and `$ZDOTDIR/.zlogout` are available for
modifications, albeit missing by default.

### Lazy \*env

Pyenv and similar wrappers are lazy-loaded, it means that they won't be
initialized on shell start. Activation is done on the first execution. Check
out output of `type -f pyenv` in shell and
[implementation](zsh/.zshrc). Also this means, that files like
`.python-versear
on` won't work as expected, it's recommended to use autoenv.zsh
to explicitly activate needed environment.
