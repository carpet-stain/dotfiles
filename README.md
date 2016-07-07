# There are many like it, but this one is mine

This repostory holds conguration for most common tools I use in shell. No
graphical stuff, usable both on server and personal workstation. Battle
tested on OSX and various Linux distributions including Debian, Ubuntu, CentOS.

I'm a big fan of [XDG Base Directory
Specification](http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html)
and organize my dotfiles in a way that they don't clutter the `$HOME`. I was
able to reduce files required to be in `$HOME` to single `.zshenv`, everything
else goes under standard XDG paths or launched via aliases.

# Features

* Extensive Zsh [configuration](zsh/zshrc)
  * [completions plugin](https://github.com/zsh-users/zsh-completions)
  * [autosuggestions plugin](https://github.com/tarruda/zsh-autosuggestions)
  * [history substring search plugin](https://github.com/zsh-users/zsh-history-substring-search)
  * [syntax highlighting plugin](https://github.com/zsh-users/zsh-syntax-highlighting)
  * [zaw](https://github.com/zsh-users/zaw) and [cdr](https://github.com/willghatch/zsh-cdr)
* Vim [configuration](vim/vimrc) and [plugins](vim/bundle) managed by [pathogen](https://github.com/tpope/vim-pathogen)
* tmux [configuration](tmux.conf) and [plugins](tmux/plugins)
* Midnight Commander [configuration](mc.ini)
* quilt [configuration](quiltrc)
* Git [config](gitconfig)
* Handy utilities
  * [MySQLTuner](https://github.com/major/MySQLTuner-perl)
  * [MongoDB Shell Enhancements](https://github.com/TylerBrock/mongo-hacker)
  * [`k`](https://github.com/rimraf/k), modern `ls` with bells and whistles
  * [spark](https://github.com/holman/spark) to draw bar charts right in the console
  * [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy) for much better git diff layout
  * [pyenv](https://github.com/yyuu/pyenv) and [rbenv](https://github.com/rbenv/rbenv)
  * vpaste uploader

# Installation

Requirements:
* `zsh` (for obvious reasons)
* `make` (mongo-hacker uses it for [js concatenation](https://github.com/TylerBrock/mongo-hacker/blob/master/Makefile#L9-L10))

Dotfiles can be installed in any dir, but probably somewhere under `$HOME`.
Personally I use `$HOME/.local/dotfiles`. The installation is pretty simple:
```sh
mkdir $HOME/.local
cd $HOME/.local
git clone https://github.com/z0rc/dotfiles.git
cd dotfiles
./deploy.sh
```

[Simple deployment script](deploy.sh) helps to set up all required symlinks
after the initial clone. Also it adds cron job to pull updates every midnight
and serves as a post-merge git hook, so you don't have to care about updating
submodules after successful pull.
