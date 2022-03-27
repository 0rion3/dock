if test -e "$HOME/.shared_shell_env"; then
  source $HOME/.shared_shell_env
fi

export PS1="Docker \u@$(head -1 /proc/self/cgroup | cut -d/ -f3 | cut -c1-6) |"

if [ -n "$DISPLAY" -a "$TERM" == "xterm" ]; then
  export TERM=xterm-256color
else
  export TERM="xterm"
fi

export HISTIGNORE=' *'
unset MAILCHECK
export SSL_CERT_FILE=/usr/lib/ssl/certs/ca-certificates.crt
