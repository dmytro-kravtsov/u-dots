source ~/.zshenv

# history wrapper
function omz_history {
  local clear list
  zparseopts -E c=clear l=list
  if [[ -n "$clear" ]]; then
    # if -c provided, clobber the history file
    echo -n >| "$HISTFILE"
    fc -p "$HISTFILE"
    echo >&2 History file deleted.
  elif [[ -n "$list" ]]; then
    # if -l provided, run as if calling `fc' directly
    builtin fc "$@"
  else
    # unless a number is provided, show all history events (starting from 1)
    [[ ${@[-1]-} = *[0-9]* ]] && builtin fc -l "$@" || builtin fc -l "$@" 1
  fi
}
# timestamp format
case ${HIST_STAMPS-} in
  "mm/dd/yyyy") alias history='omz_history -f' ;;
  "dd.mm.yyyy") alias history='omz_history -E' ;;
  "yyyy-mm-dd") alias history='omz_history -i' ;;
  "") alias history='omz_history' ;;
  *) alias history="omz_history -t '$HIST_STAMPS'" ;;
esac
# history file configuration
[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history"
[ "$HISTSIZE" -lt 50000 ] && HISTSIZE=50000
[ "$SAVEHIST" -lt 10000 ] && SAVEHIST=10000
# history command configuration
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt share_history          # share command history data

# ssh agent
if (( $+commands[ssh-agent] )); then
  # Set the path to the SSH directory.
  _ssh_dir="$HOME/.ssh"
  # Set the path to the environment file if not set by another module.
  _ssh_agent_env="${_ssh_agent_env:-${XDG_CACHE_HOME:-$HOME/.cache}/ssh-agent/ssh-agent.env}"
  # Set the path to the persistent authentication socket.
  _ssh_agent_sock="${XDG_CACHE_HOME:-$HOME/.cache}/ssh-agent/ssh-agent.sock"
  # Start ssh-agent if not started.
  if [[ ! -S "$SSH_AUTH_SOCK" ]]; then
    # Export environment variables.
    source "$_ssh_agent_env" 2> /dev/null
    # Start ssh-agent if not started.
    if ! ps -U "$LOGNAME" -o pid,ucomm | grep -q -- "${SSH_AGENT_PID:--1} ssh-agent"; then
      mkdir -p "$_ssh_agent_env:h"
      eval "$(ssh-agent | sed '/^echo /d' | tee "$_ssh_agent_env")"
    fi
  fi
  # Create a persistent SSH authentication socket.
  if [[ -S "$SSH_AUTH_SOCK" && "$SSH_AUTH_SOCK" != "$_ssh_agent_sock" ]]; then
    mkdir -p "$_ssh_agent_sock:h"
    ln -sf "$SSH_AUTH_SOCK" "$_ssh_agent_sock"
    export SSH_AUTH_SOCK="$_ssh_agent_sock"
  fi
  # Load identities.
  if ssh-add -l 2>&1 | grep -q 'The agent has no identities'; then
    # ssh-add has strange requirements for running SSH_ASKPASS, so we duplicate
    # them here. Essentially, if the other requirements are met, we redirect stdin
    # from /dev/null in order to meet the final requirement.
    #
    # From ssh-add(1):
    # If ssh-add needs a passphrase, it will read the passphrase from the current
    # terminal if it was run from a terminal. If ssh-add does not have a terminal
    # associated with it but DISPLAY and SSH_ASKPASS are set, it will execute the
    # program specified by SSH_ASKPASS and open an X11 window to read the
    # passphrase.
    if [[ -n "$DISPLAY" && -x "$SSH_ASKPASS" ]]; then
      ssh-add ${_ssh_identities:+$_ssh_dir/${^_ssh_identities[@]}} < /dev/null 2> /dev/null
    else
      ssh-add ${_ssh_identities:+$_ssh_dir/${^_ssh_identities[@]}} 2> /dev/null
    fi
  fi
  # Clean up.
  unset _ssh_{dir,identities} _ssh_agent_{env,sock}
fi

alias zreload='exec zsh'
alias x='exit'
alias ll='ls -la' # Lists in one column, hidden files.
alias l='ls -l' # Lists in one column.
alias rm='trash'
alias n='nnn -deU'

alias ip='ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '\''{print $2}'\'
alias flushdns='sudo killall -HUP mDNSResponder;sudo killall mDNSResponderHelper;sudo dscacheutil -flushcache'

function myip() {
# about 'displays your ip address, as seen by the Internet'
  list=("http://myip.dnsomatic.com/" "http://checkip.dyndns.com/" "http://checkip.dyndns.org/")
  for url in ${list[*]}; do
      res=$(command curl -s "${url}")
      if [ $? -eq 0 ]; then
          break
      fi
  done
  res=$(echo "$res" | grep -Eo '[0-9\.]+')
  echo -e "Your public IP is: ${echo_bold_green} $res ${echo_normal}"
}

#ruckus
export RKSCLOUD="$HOME/dev/rks"
alias rks='cd $RKSCLOUD'

function up() {
  # about 'update brew packages'
  brew update
  brew upgrade
  brew cleanup
  ls -l $HOMEBREW_FOLDER/Library/Homebrew | grep homebrew-cask |
    awk '{print $9}' | for evil_symlink in $(cat -); do rm -v $HOMEBREW_FOLDER/Library/Homebrew/$evil_symlink; done
  brew doctor
}

function up-cask() {
  # about update outdated casks
  OUTDATED=$(brew outdated --cask --greedy --verbose|sed -E '/latest/d'|awk '{print $1}' ORS=' '|tr -d '\n')
  # OUTDATED=$(brew outdated --cask --verbose|sed -E '/latest/d'|awk '{print $1}' ORS=' '|tr -d '\n')
  echo "outdated: $OUTDATED"
  [[ ! -z "$OUTDATED" ]] && brew reinstall --cask ${=OUTDATED}
}


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
