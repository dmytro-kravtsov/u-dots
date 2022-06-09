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
