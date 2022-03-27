# This file wa slightly customize such that
#
# 1. OH-MY-ZSH lib files are load form $ZSH/oh-my-zsh-lib/ and NOT just $ZSH/lib directory.
#    That's because there are no plans to fully use oh-my-zsh as it is
#    intended.
#
# 2. Theme files have the .zsh extension and not .zsh-theme.
#    Who wants to go and play with their text editor settings to highlight
#    zsh code in a file that someone decided should not have the .zsh extension?
#    Ugh.
#
# 3. ZSH_COMPDUMP changed from the original. They dumped all these files
#    into $HOME polluting it. Now it's placed in .cache/zsh

# Set ZSH_CACHE_DIR to the path where cache files should be created
# or else we will use the default cache/
if [[ -z "$ZSH_CACHE_DIR" ]]; then
  ZSH_CACHE_DIR="$ZSH/cache"
fi

# Check for updates on initial load...
if [ "$DISABLE_AUTO_UPDATE" != "true" ]; then
  source $ZSH/tools/check_for_upgrade.sh
fi

# Initializes Oh My Zsh

# add a function path
fpath=($ZSH/functions $ZSH/completions $fpath)

# Load all stock functions (from $fpath files) called below.
autoload -U compaudit compinit

# Set ZSH_CUSTOM to the path where your custom config files
# and plugins exists, or else we will use the default custom/
if [[ -z "$ZSH_CUSTOM" ]]; then
  ZSH_CUSTOM="$ZSH/.zsh-custom"
fi


is_plugin() {
  local base_dir=$1
  local name=$2
  builtin test -f $base_dir/plugins/$name/$name.plugin.zsh \
    || builtin test -f $base_dir/plugins/$name/_$name
}

# Add all defined plugins to fpath. This must be done
# before running compinit.
for plugin ($plugins); do
  if is_plugin $ZSH_CUSTOM $plugin; then
    fpath=($ZSH_CUSTOM/plugins/$plugin $fpath)
  elif is_plugin $ZSH $plugin; then
    fpath=($ZSH/plugins/$plugin $fpath)
  else
    echo "[oh-my-zsh] plugin '$plugin' not found"
  fi
done

# Figure out the SHORT hostname
if [[ "$OSTYPE" = darwin* ]]; then
  # macOS's $HOST changes with dhcp, etc. Use ComputerName if possible.
  SHORT_HOST=$(scutil --get ComputerName 2>/dev/null) || SHORT_HOST=${HOST/.*/}
else
  SHORT_HOST=${HOST/.*/}
fi

# CHANGED FROM THE ORIGINAL: 

# Set the location of the current completion dump file, meaning
# placing .zcompdump* files under ~/.cache, so they don't pollute the home dir
# and dock/cleanup_container script already knows to remove all files from ~/.cache
# We do it before sourcing $ZSH/oh-my-zsh.sh as it checks if this variable exists.
#
# Eventually this oh-my-zsh non-sense will be filtered out completely, so we won't
# have to dance around it.
if [ -z "$ZSH_COMPDUMP" ]; then
  mkdir -p $HOME/.cache/zsh # create the .zsh cache directory if doesn't exist.
  ZSH_COMPDUMP="${ZDOTDIR:-${HOME}}/.cache/zsh/zcompdump-${DOCKER_IMAGE_SUFFIX}_${DOCKER_PROJECT_NAME}-${ZSH_VERSION}"
fi

# Construct zcompdump OMZ metadata
zcompdump_revision="#omz revision: $(builtin cd -q "$ZSH"; git rev-parse HEAD 2>/dev/null)"
zcompdump_fpath="#omz fpath: $fpath"

# Delete the zcompdump file if OMZ zcompdump metadata changed
if ! command grep -q -Fx "$zcompdump_revision" "$ZSH_COMPDUMP" 2>/dev/null \
   || ! command grep -q -Fx "$zcompdump_fpath" "$ZSH_COMPDUMP" 2>/dev/null; then
  command rm -f "$ZSH_COMPDUMP"
  zcompdump_refresh=1
fi

if [[ $ZSH_DISABLE_COMPFIX != true ]]; then
  source $ZSH/oh-my-zsh-lib/compfix.zsh
  # If completion insecurities exist, warn the user
  handle_completion_insecurities
  # Load only from secure directories
  compinit -i -C -d "${ZSH_COMPDUMP}"
else
  # If the user wants it, load from all found directories
  compinit -u -C -d "${ZSH_COMPDUMP}"
fi

# Append zcompdump metadata if missing
if (( $zcompdump_refresh )); then
  # Use `tee` in case the $ZSH_COMPDUMP filename is invalid, to silence the error
  # See https://github.com/ohmyzsh/ohmyzsh/commit/dd1a7269#commitcomment-39003489
  tee -a "$ZSH_COMPDUMP" &>/dev/null <<EOF

$zcompdump_revision
$zcompdump_fpath
EOF
fi

unset zcompdump_revision zcompdump_fpath zcompdump_refresh


# Load all of the config files in ~/oh-my-zsh that end in .zsh
# TIP: Add files you don't want in git to .gitignore
for config_file ($ZSH/oh-my-zsh-lib/*.zsh); do
  custom_config_file="${ZSH_CUSTOM}/oh-my-zsh-lib/${config_file:t}"
  [ -f "${custom_config_file}" ] && config_file=${custom_config_file}
  source $config_file
done

# Load all of the plugins that were defined in ~/.zshrc
for plugin ($plugins); do
  if [ -f $ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh ]; then
    source $ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh
  elif [ -f $ZSH/plugins/$plugin/$plugin.plugin.zsh ]; then
    source $ZSH/plugins/$plugin/$plugin.plugin.zsh
  fi
done

# Load all of your custom configurations from custom/
for config_file ($ZSH_CUSTOM/*.zsh(N)); do
  source $config_file
done
unset config_file

# Load the theme
if [ ! "$ZSH_THEME" = ""  ]; then
  if [ -f "$ZSH_CUSTOM/$ZSH_THEME.zsh" ]; then
    source "$ZSH_CUSTOM/$ZSH_THEME.zsh"
  elif [ -f "$ZSH_CUSTOM/themes/$ZSH_THEME.zsh" ]; then
    source "$ZSH_CUSTOM/themes/$ZSH_THEME.zsh"
  else
    source "$ZSH/themes/$ZSH_THEME.zsh"
  fi
fi
