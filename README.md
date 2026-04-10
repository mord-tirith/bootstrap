# bootstrap
My Neovim, Kitty and Zsh bootstrap routine

## Info
This repository holds a collection of my scripts for convenience when using Neovim and zsh, as well as Kitty/Kitten mostly just for easy color palette change in terminal.

Running ./bootstrap.sh will do the following:

1 - Install Neovim to ~/.local
2 - Install Kitty to ~/.local
3 - Copy copious configurations for Neovim, including but not limited to: 42 Norminette and Header, File system search, Left-Handed-Conveniency shortcuts
4 - Copy far far fewer configurations for Kitty, by default Catpuccin Mocha theme is set
5 - Install bat, tree and fd to ~/.local
6 - Install my pet scripts, log_all and locate to ~/.local
7 - Prepare zsh settings
8 - Symlink all of the above configurations to ~/.dotfiles where you can change the settings on your own

Once the script is done running, I highly recommend closing the terminal emulator and launching the newly-installed Kitty to use the setting to its full potential.

The script also accepts -u|--uninstall as flags to remove all configuration, or -f|--force to update programs (most of the installed things have scripts to hunt for the latest version, which --force will write over older instalations).
