#! /bin/zsh

# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

export PATH="/usr/local/bin/:/opt/homebrew/bin/:$PATH"

cat > $HOME/Brewfile <<- "EOF"
tap "homebrew/bundle"
tap "homebrew/cask"
tap "homebrew/core"
brew "maven"
brew "nnn"
brew "git"
cask "homebrew/cask-versions/temurin11"
cask "intellij-idea-ce"
cask "visual-studio-code"
cask "slack"
cask "sourcetree"
brew "trash"
brew "kubectl"
brew "fzf"
brew "kubectx"
cask "google-cloud-sdk"
cask "lens"
cask "telegram"
cask "skype"
cask "discord"
cask "zoom"
cask "brave-browser"
cask "google-chrome"
cask "vivaldi"
cask "firefox"
cask "opera"
cask "intellij-idea"
brew "minikube"
brew "skaffold"
brew "helm"
cask "docker"
cask "iterm2"
cask "cheatsheet"
cask "postman"
brew "wezterm"
brew "httpie"
EOF
# brew install lens

echo "installing Brewfile ..."
brew bundle --file=$HOME/Brewfile
echo "Brewfile installed"

# create folders
mkdir -p $HOME/dev/rks

# backup
[[ -f $HOME/.zshrc ]] && mv $HOME/.zshrc $HOME/.zshrc.old
[[ -f $HOME/.zshenv ]] && mv $HOME/.zshenv $HOME/.zshenv.old
[[ -f $HOME/.zprofile ]] && mv $HOME/.zprofile $HOME/.zprofile.old

cd $HOME
# setup .zshrc
cat > $HOME/.zshrc <<- "EOF"
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
alias ahook='$RKSCLOUD/settings-xml/bin/install-git-hook'
alias amvn='mvn -s .alto-maven-settings.xml'
EOF
# setup .zshenv
cat > $HOME/.zshenv <<- "EOF"
# check apple arch (m1/intel)
_APPLE_ARCH="unknown"
if [ "$(uname -p)" = "i386" ]; then
  _APPLE_ARCH="intel"
else
  _APPLE_ARCH="m1"
fi
export APPLE_ARCH="$_APPLE_ARCH"
unset _APPLE_ARCH

if [ "$APPLE_ARCH" = "m1" ]; then
  export HOMEBREW_FOLDER="/opt/homebrew"
else
  export HOMEBREW_FOLDER="/usr/local"
fi

export HOMEBREW_OPT="$HOMEBREW_FOLDER/opt"
export HOMEBREW_CASK_OPTS=--no-quarantine

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ($SHLVL -eq 1 && ! -o LOGIN) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

# Add /usr/local/bin to PATH because of docker cask incorrect installation on M1 Apple Silicon
PATH="$HOMEBREW_FOLDER/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"

# Java
export _JAVA_OPTIONS="-Djava.net.preferIPv4Stack=true"
export JAVA_HOME=$(/usr/libexec/java_home -v11)
[[ -d $JAVA_HOME ]] && PATH="$JAVA_HOME/bin:$PATH"

# Maven
M2="$HOMEBREW_OPT/maven"
if [ -d "$M2" ]; then
  export M2_HOME="$M2/libexec"
  PATH="$M2/bin:$PATH"
fi
export PATH=".:$PATH"
EOF
# setup .zprofile
cat > $HOME/.zprofile <<- "EOF"
# Language
if [[ -z "$LANG" ]]; then
export LANG='en_US.UTF-8'
fi

# Paths
# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path

# Set the list of directories that Zsh searches for programs.
path=(
$HOMEBREW_FOLDER/{bin,sbin}
$path
)

# Less
# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
export LESS='-F -g -i -M -R -S -w -X -z-4'

# Set the Less input preprocessor.
# Try both `lesspipe` and `lesspipe.sh` as either might exist on a system.
if (( $#commands[(i)lesspipe(|.sh)] )); then
export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"
fi
# eval "$(/opt/homebrew/bin/brew shellenv)"
EOF

# setup .ssh/config
cat > $HOME/.ssh/config <<- "EOF"
Host bitbucket.rks-cloud.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_rsa
EOF

RUCKUS_HOST="ruckuswireless.com"
echo "Please enter <Name>.<Surname> for your <Name>.<Surname>@$RUCKUS_HOST email address:"
read RUCKUS_NAME
RUCKUS_MAIL="$RUCKUS_NAME@$RUCKUS_HOST"
echo "Generating ruckus ssh-key for \"$RUCKUS_MAIL\", please do not enter pasphrase"
ssh-keygen -t ed25519 -C "$RUCKUS_MAIL"
git config --global user.name "$RUCKUS_NAME"
git config --global user.email "$RUCKUS_MAIL"
echo "Register this key in Bitbucket:\n"
cat $HOME/.ssh/id_ed25519.pub
echo "\nDone"
