if test -e "$HOME/.shared_shell_env"; then
  source $HOME/.shared_shell_env
fi

if [ -n "$DISPLAY" -a "$TERM" == "xterm" ]; then
  export TERM=xterm-256color
else
  export TERM="xterm"
fi

export HISTIGNORE=' *'
unset MAILCHECK
export SSL_CERT_FILE=/usr/lib/ssl/certs/ca-certificates.crt

bind '"s": self-insert' 2> /dev/null
