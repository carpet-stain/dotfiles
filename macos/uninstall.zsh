# Remove Homebrew Packages
print "Removing Homebrew packages..."
brew list | xargs brew uninstall --force

print "Removing Homebrew casks..."
brew list --cask | xargs brew uninstall --force

# Uninstall Homebrew
print "Removing Homebrew itself..."
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

# Remove command line tools
print "Removing Command Line Tools..."
sudo rm -rf /Library/Developer/CommandLineTools

