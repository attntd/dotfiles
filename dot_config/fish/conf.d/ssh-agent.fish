set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"
set -gx SSH_ASKPASS "$HOME/.config/quickshell/services/askpass.py"
set -gx SUDO_ASKPASS "$HOME/.config/quickshell/services/askpass.py"
