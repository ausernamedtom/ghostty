MATRIX_SHELL_DIR=$ZDOTDIR
ZDOTDIR=$MATRIX_ORIGINAL_ZDOTDIR
# Load before the user .zshrc, as Ghostty does. Loaded after Powerlevel10k, it edits
# the two-line prompt inside its expansions and prints ":-" and "}}".
if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
  source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"
fi
[[ -r "$ZDOTDIR/.zshrc" ]] && source "$ZDOTDIR/.zshrc"
source "$MATRIX_SHELL_DIR/heat.zsh"
