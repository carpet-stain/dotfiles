#!/usr/bin/env zsh

  # Initialize colors
  autoload -Uz colors
  colors

  # Enhanced word navigation (e.g., for Alt-Left/Right arrows)
  # 'autoload -Uz' is the standard, safe way to load a Zsh function.
  #   -U: Marks for autoloading, disables alias expansion.
  #   -z: Loads in "zsh" compatibility mode.
  autoload -Uz forward-word backward-word
  # 'zle -N' creates a new "widget" (a line-editor command)
  # named 'forward-word' that calls the function 'forward-word'.
  zle -N forward-word
  zle -N backward-word

  # 'select-word-style bash' makes word-deletion widgets (like Ctrl+W)
  # behave like Bash, stopping at path delimiters (/) instead of
  # deleting the whole path.
  autoload -Uz select-word-style
  select-word-style bash

  # enable url-quote-magic
  # This widget automatically quotes special characters in URLs
  # when you paste them into the command line.
  autoload -Uz url-quote-magic
  zle -N self-insert url-quote-magic

  # enable bracketed paste
  # This prevents pasted code (especially multi-line code) from
  # auto-executing. It pastes it as a single, safe block.
  autoload -Uz bracketed-paste-magic
  zle -N bracketed-paste bracketed-paste-magic

  # Use default provided history search widgets
  # These are the functions that power the "search-as-you-type"
  # history when you press the Up/Down arrows.
  autoload -Uz up-line-or-beginning-search
  zle -N up-line-or-beginning-search
  autoload -Uz down-line-or-beginning-search
  zle -N down-line-or-beginning-search

  # Load custom functions
  # Autoload all custom functions from our $fpath (e.g., ~/.config/zsh/fpath)
  # These files must be named *exactly* the same as the function.
  autoload -Uz \
    _zsh-dot \
    _expand-alias \
    _chpwd-eza \
    _zsh-cursor-shape-reset \
    _zsh-cursor-shape-ibeam

  # Create Zle widgets for each of our custom functions so they can be bound to keys.
  zle -N _zsh-dot
  zle -N _expand-alias
  zle -N _chpwd-eza
  zle -N _zsh-cursor-shape-ibeam
  zle -N _zsh-cursor-shape-reset

  # Ensure add-zsh-hook is loaded
  autoload -Uz add-zsh-hook

  # +----------------+
  # | ZSH HOOKS      |
  # +----------------+
  # Hooks run custom functions at specific points in the shell's lifecycle.

  # 'chpwd' hook: Runs *every time* the directory is changed.
  # This calls our custom '_chpwd-eza' function (which runs 'eza').
  add-zsh-hook chpwd _chpwd-eza

  # 'preexec' hook: Runs *just before* a command is executed.
  # This calls our widget to change the cursor to a BLOCK (reset).
  add-zsh-hook preexec _zsh-cursor-shape-reset

  # 'precmd' hook: Runs *just before* the prompt is drawn.
  # This calls our widget to change the cursor to an I-BEAM.
  add-zsh-hook precmd _zsh-cursor-shape-ibeam

  # +--------------------+
  # | ZLE (LINE EDITOR)  |
  # +--------------------+

  # Don't eat space after '<Tab>' followed by '&' or '|'
  ZLE_SPACE_SUFFIX_CHARS="&|"

  # Eat space after '<Tab>' followed by ')', etc.
  ZLE_REMOVE_SUFFIX_CHARS=" \t\n;)"

  # Removes the syntax highlighting "flash" when pasting text.
  zle_highlight+=(paste:none)