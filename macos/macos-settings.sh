#!/usr/bin/env sh

# Quit System Preferences so it doesn't override settings
osascript -e 'tell application "System Preferences" to quit'

# Faster key repeat
defaults write -g InitialKeyRepeat -int 12
defaults write -g KeyRepeat -int 2

# Disable press and hold for special characters
defaults write -g ApplePressAndHoldEnabled -bool false

# Default to the list view in Finder
defaults write com.apple.finder FXPreferredViewStyle Nlsv

# Show the full path at the bottom of Finder
defaults write com.apple.finder ShowPathbar -bool true

# Show all file extensions
defaults write -g AppleShowAllExtensions -bool true

# Unhide the ~/Library folder
chflags nohidden ~/Library

# Hide the Dock
defaults write com.apple.dock autohide -bool true

# Don't show recent apps in the Dock
defaults write com.apple.dock show-recents -bool false

# Hide the "Now Playing" menu bar item
defaults write com.apple.controlcenter "NSStatusItem Visible NowPlaying" -bool false

# Save screenshots in the Screncaps folder
defaults write com.apple.screencapture location ~/Documents/Screencaps

# See the changes
killall Dock
killall Finder
killall SystemUIServer
