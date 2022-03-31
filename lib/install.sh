#!/usr/bin/env bash

# Check if minimum requirements are satisfied. If not,
# print the list of those that are not installed and exit.
check_requirements() {
  printf "$(color dim)"
  printf "$(ind 4)* Checking requirements..."
  requirements=( bash git sed awk ssh docker curl )
  satisfied_requirements=()
  missing_requirements=()
  for req in "${requirements[@]}"; do
    result="$(which $req)"
    if [[ -n "$result" ]]; then
      satisfied_requirements+=( $req )
    else
      missing_requirements+=( $req )
    fi
  done


  if [[ ! ${#missing_requirements[@]} -eq 0 ]]; then
    >&2 echo -e "$(color red)ERROR: Missing requirements: $(color cyan)${missing_requirements[@]}"
    >&2 echo -e "$(color off; color dim)Cannot continue.$(color off)"
    exit 1
  else

    function print_bash_version_error() {
      >&2 echo -e "$(color red)ERROR: your bash version is <= 4.2"
      >&2 echo -e "$(color off; color dim)Cannot continue.$(color off)"
    }

    bash_version="$(bash --version | grep -oE 'version [0-9]\.[0-9]' | sed 's/version //')"
    bash_major_version=$(( $(echo "$bash_version" | sed 's/\.[0-9]$//') ))
    bash_minor_version=$(( $(echo "$bash_version" | sed 's/^[0-9]\.//' ) ))

    if [[ $bash_major_version -lt 4 ]]; then
      print_bash_version_error
      exit 1
    fi

    if [[ $bash_major_version -eq 4 ]] && [[ $bash_minor_version -lt 2 ]]; then
      print_bash_version_error
      exit 1
    fi

    echo -e "OK\n"
  fi
}

# Create a new docker network bridge, name it $DOCK_NETWORK_NAME
# and find out its ip address range. If already exists, just get the ip
# address range.
create_network() {
  printf "\n$(color dim)"
  echo -en "$(ind 4)* Creating a dock0 network bridge..."
  if [[ -n "$(docker network ls | grep "\s$DOCK_NETWORK_NAME\s")" ]]; then
    echo "ALREADY EXISTS"
  else
    network_bridge_id="$(docker network create $DOCK_NETWORK_NAME)"
    echo "DONE."
  fi

  network_ip_range=$(docker network inspect $DOCK_NETWORK_NAME | \
    grep 'Gateway":' | grep -oE '"[^"]+"$' | tr -d '"' | sed 's/.1$//'
  )
}

import_image() {
  printf "$(color dim)"
  echo -e "$(ind 4)* Obtaining/locating default image"
  while [[ $user_input_image == "" ]]; do
    echo -e "$(ind 8; color off)Do you have the default image or do you want to download it?"
    echo -en "$(ind 8)(d) - download, or type path to file: "
    read user_input_image
    printf "$(color dim)"
    if [[ "$user_input_image" == "" ]]; then
      echo -e "\n$(ind 8; color yellow)Sorry, need some input, not sure what you want."
      echo -e "$(ind 8; color yellow)You can also press Ctrl+C or type q to quit.\n"
    fi
  done

  if [[ "$user_input_image" == "d" ]]; then
    echo -e "\n$(ind 8; color off)Would you consider downloading it via BitTorrent magnet link?"
    echo -e "$(ind 10; color green)(y) - yes, I'll try BitTorrent, give me the link."
    echo -e "$(ind 10; color yellow)(n or d) - no, download it for me now automatically."
    echo -en "$(ind 8; color off)Enter your choice: "

    read user_input_bittorrent

    printf "$(color dim)"

    if [[ $user_input_bittorrent == "y" ]]; then
      source $DOCK_PATH/bin/image import default magnet
    elif [[ $user_input_bittorrent == "n" ]] || [[ $user_input_bittorrent == "d" ]]; then
      source $DOCK_PATH/bin/image import default hub
    fi
  elif [[ "$user_input_image" == "q" ]]; then
    echo -e "Exiting.$(color off)"
    exit 2
  else
    source $DOCK_PATH/bin/image import $user_input_image file
  fi
}


# Copy dockrc.template to $HOME/.dockrc
# If the file already exists, then ask user if they'd like to replace it.
copy_dokrc() {
  printf "\n$(color dim)"
  echo -en "$(ind 4)* Creating ~/.dockrc from a template..."
  if test -f $HOME/.dockrc; then
    echo -e "\n$(ind 4; color yellow)File ~/.dockrc already exists."
    echo -en "$(ind 4;)Would you like to overwrite it? (y/n):$(color off) "
    read user_input_overwrite_dockrc
    if [[ $user_input_overwrite_dockrc == "y" ]]; then
      rm $HOME/.dockrc
      cp $DOCK_PATH/dockrc.template $HOME/.dockrc
      echo -e "$(ind 8)FILE ~/.dockrc OVERWRITTEN."
    else
      echo -e "$(ind 8)OK. File ~/.dockrc left as is, no changes will be applied to it"
      return 1
    fi
  else
    cp $DOCK_PATH/dockrc.template $HOME/.dockrc
    echo "DONE.\n"
  fi
}

# We'll spare the user the manual editing of ~/.dockrc by replacing
# a few values inside the ~/.dockrc file that might be specific to
# their environment on the current machine or that are provided via
# prepended variables when running ./install
replace_default_values_in_dockrc() {
  printf "\n$(color dim)"
  echo -e "$(ind 4)* Setting default values in ~/.dockrc"
  local repo="$(Image_extract_repo $image_full_name)"
  local name="$(Image_extract_name $image_full_name)"
  local tag="$(Image_extract_tag $image_full_name)"
  sed -iE "s|^DOCK_PATH=.*$|DOCK_PATH=\"$DOCK_PATH\"|"                         $HOME/.dockrc
  sed -iE "s|^DEFAULT_IMAGE_REPO=.*$|DEFAULT_IMAGE_REPO=\"$repo\"|"            $HOME/.dockrc
  sed -iE "s|^DEFAULT_IMAGE_NAME=.*$|DEFAULT_IMAGE_NAME=\"$name\"|"            $HOME/.dockrc
  sed -iE "s|^DEFAULT_IMAGE_TAG=.*$|DEFAULT_IMAGE_TAG=\"$tag\"|"               $HOME/.dockrc
  sed -iE "s|^DOCK_NETWORK_NAME=.*$|DOCK_NETWORK_NAME=\"$DOCK_NETWORK_NAME\"|" $HOME/.dockrc
  sed -iE "s|^DOCK_SUBNET=.*$|DOCK_SUBNET=\"$network_ip_range\"|"              $HOME/.dockrc

  echo "$(ind 8)Set DOCK_PATH to \"$DOCK_PATH\""
  echo "$(ind 8)Set DEFAULT_IMAGE_REPO to \"$repo\""
  echo "$(ind 8)Set DEFAULT_IMAGE_NAME to \"$name\""
  echo "$(ind 8)Set DEFAULT_IMAGE_TAG to \"$tag\""
  echo "$(ind 8)Set DOCK_NETWORK_NAME to \"$DOCK_NETWORK_NAME\""
  echo "$(ind 8)Set DOCK_SUBNET to \"$network_ip_range\""

  echo -e "$(color off)"
  echo -e "$(ind 8)When creating containers, \`dock\` relies on directory path to"
  echo -e "$(ind 8)assign a name - unless it's specified explicitly."
  echo -e "$(ind 8)However, it isn't necessary to include $HOME into each container name."
  echo -e "$(ind 8)Therefore the \$IGNORED_PREFIX_PATH variable is used to mark the part"
  echo -e "$(ind 8)of the path that shall not be used when assigning a name."
  echo -e "$(ind 8; color yellow)Would you like to keep the default value of \$IGNORED_PREFIX_PATH?"
  echo -e "$(ind 8; color yellow)If YES - just leave blank and press ENTER,"
  echo -en "$(ind 8; color yellow)If NO - type your own prefix here:$(color off) "

  read user_input_ignored_prefix_path
  user_input_ignored_prefix_path="${user_input_ignored_prefix_path:-$HOME}"

  sed -iE "s|^IGNORED_PREFIX_PATH=.*$|IGNORED_PREFIX_PATH=\"$user_input_ignored_prefix_path\"|" $HOME/.dockrc
  echo -e "$(ind 8; color dim)Set IGNORED_PREFIX_PATH to \"$user_input_ignored_prefix_path\""

}

# Ask if the user wants to add aliases hostscripts/docker_aliases.sh
# to his shell rc file. If yes, add the line sourcing this file into
# their shell rc file.
add_docker_aliases() {
  printf "\n$(color dim)"
  echo -e "$(ind 4)* Docker aliases"
  echo -e "$(ind 10)Some useful aliases are shipped along with the dock toolset."
  echo -e "$(ind 10)They help work with Docker itself. These aliases can be added"
  echo -e "$(ind 10)to your shell's rc file with this line:"
  echo -e "$(ind 14)source $DOCK_PATH/hostscripts/docker_aliases.sh$(color off)\n"
  echo -en "$(ind 10; color off)Would you like to automatically add this line now? (y/n): "
  read add_docker_aliases

  printf "$(color dim)"
  if [[ $add_docker_aliases == "y" ]]; then
    add_aliases_to_shellrc_file "source \"$DOCK_PATH/hostscripts/docker_aliases.sh\""
  fi

}

# Command `dock` should be available in any directory so we try to find one of
# the directories inside $HOME that are in the $PATH and create a symlink there.
symlink_bin_dock_into_user_path_dir() {
  echo -e "\n$(ind 4; color dim)* Symlinking the \`dock\` executable"
  if [[ "$PATH" == *"$HOME/bin"* ]]; then
    mkdir -p $HOME/bin 
    ln -sf $DOCK_PATH/bin/dock $HOME/bin
    echo -en "$(ind 8)Created symlink to $(color off)$DOCK_PATH/bin/dock$(color dim)"
    echo -e "$executable in $(color off)~/bin$(color dim)"
  elif [[ "$PATH" == *"$HOME/.local/bin"* ]]; then
    mkdir -p $HOME/.local/bin 
    ln -sf $DOCK_PATH/bin/dock $HOME/.local/bin
    echo -en "$(ind 8)Created symlink to $(color off)$HOME/.local/bin$(color dim)"
    echo -e "$executable in $(color off)~/.local/bin$(color dim)"
  else
    printf "$(color yellow)"
    echo -e  "$(ind 8)The script couldn't identify a directory that's both in your \$PATH"
    echo -e  "$(ind 8)and is inside your current user's \$HOME."
    echo -e  "$(ind 8; color off) As an alternative option, the installation"
    echo -e  "$(ind 8)script can add an alias to for the \`dock\` executable"
    echo -e  "$(ind 8)into your current shell config file."
    echo -en "$(ind 8)Would you like the script to do it? $(color off)(y/n): "

    read add_dock_executable_as_alias

    if [[ $add_dock_executable_as_alias == "y" ]]; then
      add_aliases_to_shellrc_file "alias dock=$DOCK_PATH/bin/dock"
    fi

  fi
}

function add_aliases_to_shellrc_file() {
  if test -f $HOME/.${USER_SHELL}rc; then
    echo "$1" >> $HOME/.${USER_SHELL}rc
    echo -e "$(ind 14)Added alias(es) to ~/.${USER_SHELL}rc"
    echo -e "$(ind 14)You will need to restart your terminal for it to work". 
  else
    >&2 echo -e "\n$(color yellow)WARNING: we detected your shell to be ${USER_SHELL},"
    >&2 echo -e "but couldn't find the environment file \$HOME/.${USER_SHELL}rc"
    >&2 echo -e "Please add the necessary alias(es) yourself\n".
    return 1
  fi
}
