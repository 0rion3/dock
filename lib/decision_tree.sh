# IMPORTANT!!!
# This is THE DECISION TREE implementation as it is described in the
# corresponding section of the README file. As this is the most important
# part, DO NOT deviate from the behavior describe in README or update README
# immediately if any changes were made. It may not seem like much, as the
# description is probably much more elaborate than the implementation. But
# it has to be handled (fixed, improved, changed) with special care and
# attention to details.
#
# The conditionals follow the order in the README description.
#
# Before we decide what to do (in THE DECISION TREE code below) we must
# determine project information implied from the current directory the user
# is running the ./dock command from.
directory_info="$($DOCK_PATH/bin/directory_info)"
  echo "$directory_info" | assign_vars_from_out
#
#
# THE DECISION TREE SECTION (1) - both positional arguments provided
if [[ -n $pos_arg1 ]] && [[ -n $pos_arg2 ]]; then
  image_info="$($DOCK_PATH/bin/image_info $pos_arg1)"
    echo "$image_info" | assign_vars_from_out
  container_info="$($DOCK_PATH/bin/container_info $pos_arg2)"
    echo "$container_info" | assign_vars_from_out

  if [[ -n $image_name ]] && [[ -n $conainer_name ]]; then
    # THE DECISION TREE case 1.1 fulfilled: both image and container exist
    decision_tree_result="1.1"
  elif [[ -n $image_name ]] && [[ -z $conainer_name ]]; then
    # THE DECISION TREE case 1.2 fulfilled: image exists, but not the container
    decision_tree_result="1.2"
  elif [[ -z "$image_name$container_name" ]]; then
    # THE DECISION TREE case 1.3 fulfilled Neither image, nor container were found.
    decision_tree_result="ERROR (1.3)"
    printf "$(ind 4)$(color red)$decision_tree_result:\n"
    printf "$(ind 4)Both image and container names your provided couldn't match any existing ones."
  elif [[ -n "$container_name" ]] && [[ "$container_image_name" != "$full_image_name" ]]; then
    # Image on which the container is based on is not found.
    # Exit with status 1 - fulfills THE DECISION TREE case 1.4
    decision_tree_result="(ERROR) 1.4"
    printf "$(ind 4)$(color red)$decision_tree_result:\n"
    printf "$(ind 4)Image $(color yellow)$pos_arg1$(color red) is NOT the same "
    printf "the existing container $(color off)$container_image_name$(color red) is based on.\n"
  fi

  container_name="${container_name:-$pos_arg2}"
  project_info="$($DOCK_PATH/bin/project_info $container_name)"
    echo "$project_info" | assign_vars_from_out
  # If we don't exit by now, then image and container both exist or only image
  # exists. Fulfils THE DECISION TREE case 1.1 and 1.2 as ./container_info
  # provides us with the $create_new_container variable which instructs the
  # ./start_container script to create a new container from the image first.
  #
  # This completes THE DECISION TREE (1) section

# THE DECISION TREE SECTION (2) - only one positional argument is provided
elif [[ -n $pos_arg1 ]] && [[ -z $pos_arg2 ]]; then

  # Trying to find an existing container first
  container_info="$($DOCK_PATH/bin/container_info $pos_arg1)"
    echo "$container_info" | assign_vars_from_out

  if [[ -n $container_name ]]; then
    # THE DECISION TREE, case 2.1 fulfilled - CONTAINER EXISTS.
    # Next, extract more information about the image its based upon and
    # the project name based on the information we got from $container_info.
    decision_tree_result="2.1"

    image_info="$($DOCK_PATH/bin/container_info $container_image_name)"
      echo "$container_info" | assign_vars_from_out
    project_info="$($DOCK_PATH/bin/project_info $container_name)"
      echo "$project_info" | assign_vars_from_out

  else
    # CONTAINER with name $arg1 NOT FOUND, so we attempt to look up an image,
    # which name fully or partially matches the provided positional argument.
    image_info="$($DOCK_PATH/bin/image_info $pos_arg1)"
      echo "$image_info" | assign_vars_from_out
    project_info="$($DOCK_PATH/bin/project_info $PWD)"
      echo "$project_info" | assign_vars_from_out
    container_info="$($DOCK_PATH/bin/container_info $project_name)"
      echo "$container_info" | assign_vars_from_out

    if [[ -n $image_name ]]; then
      if [[ "$container_image_name" == "$full_image_name" ]]; then
        # THE DECISION TREE case 2.2.a fulfilled: IMAGE found
        # and CONTAINER name resembling current directory name and based the
        # same image also exists. It is then equivalent to just typing `dock`
        # with no arguments
        decision_tree_result="2.2.a"
        create_new_container="no"
      elif [[ -z $container_name ]]; then
        # THE DECISION TREE case 2.2.b fulfilled: a CONTAINER resembling
        # current directory name doesn't exist, so it's a fine assumption
        # user wants to create a new one based on the image which name they
        # provided in that single positional argument.
        decision_tree_result="2.2.b"
        container_name="$project_name"
      else
        # THE DECISION TREE case 2.2.c fulfilled: IMAGE found, but an existing
        # CONTAINER with the name associated with the current directory is
        # based on a different image. We inform the user that two containers
        # with the same name are not allowed and they must specify container
        # name explicitly in a second positional argument.
        decision_tree_result="ERROR (2.2.c)"
        >&2 printf "$(color red)"
        >&2 printf "$decision_tree_result:\n"
        >&2 printf "$(ind 4)Image $(color yellow)$pos_arg1$(color red) found, but an existing container\n"
        >&2 printf "$(ind 4)named $(color blue)$container_name$(color red) based on another image "
        >&2 printf "$(color yellow; color dim)$container_image_name$(color red)\n"
        >&2 printf "$(ind 4)already exists. It's not allowed to have two containers with the same name.\n"
        >&2 printf "$(ind 4)Provide container name explicitly as a 2nd positional "
        >&2 printf "argument.\n$(ind 4; color gray)Example:\n\n"
        >&2 printf "$(ind 8; color yellow)\$$(color off) dock $pos_arg1 $(color blue; color bold)${container_name}_2$(color off)\n\n"
        >&2 printf "$(ind 4;color gray)If you've made a mistake thinking the container didn't exist and you actually meant\n"
        >&2 printf "$(ind 4)to connect to an existing one either way, just type $(color yellow)\$ $(color off)dock$(color gray) "
        >&2 printf "with no arguments.\n"
        >&2 printf "$(ind 4)If you see image id instead of its name above it means the image name was simply\n"
        >&2 printf "$(ind 4)re-assigned to a different image and the container is now based on tagless image.\n"
        >&2 printf "$(ind 4)Again, this shouldn't be a problem if you just type $(color yellow)\$ $(color off)dock$(color gray) "
        >&2 printf "without providing\n"
        >&2 printf "$(ind 4)any positional arguments.\n$(color gray)\n\nExiting.\n\n"
      fi
    else
      # THE DECISION TREE case 2.2.c fulfilled: no matching container, nor
      # image is found so we'll have to exit with an error.
      decision_tree_result="ERROR (2.2.d)"
      >&2 printf "$(color red)$decision_tree_result:\n"
      >&2 printf "$(color red)No images or containers with names resembling $(color yellow)$pos_arg1 "
      >&2 printf "$(color red)were not found. Exiting.\n"
    fi

  fi

# THE DECISION TREE SECTION (3) - no positional arguments, everything id
# derived from the current directory path - $PWD variable supplied by the
# ./directory.sh script.
else
  project_info="$($DOCK_PATH/bin/project_info $PWD)"
    echo "$project_info" | assign_vars_from_out
  container_info="$($DOCK_PATH/bin/container_info $project_name)"
    echo "$container_info" | assign_vars_from_out

  if [[ -n "$container_name" ]]; then
    decision_tree_result="3.1"
    # THE DECISION TREE case 3.1 fulfilled - container found by its name
    # being derived from the current path. We now call ./image_info as we
    # did in 2.2.a, HOWEVER, the DIFFERENCE HERE is that we use the image
    # name that we got from the container info, and container name use to
    # get that info was, in turn, was implicitly derived from the current
    # directory name and - AND NOT provided by the user.
    image_info="$($DOCK_PATH/bin/image_info $container_image_name)"
      echo "$image_info" | assign_vars_from_out
  else
    image_info="$($DOCK_PATH/bin/image_info $DEFAULT_IMAGE_FULL_NAME)"
      echo "$image_info" | assign_vars_from_out
    if [[ -n "$image_info" ]]; then
      # THE DECISION TREE case 3.2 fulfilled - using default image to create
      # new container with its name derived from the current directory
      decision_tree_result="3.2"
      create_new_container="yes" 
      container_name="$project_name"
    else
      # Fulfills THE DECISION TREE case 3.3: no container found and no default
      # image found.
      decision_tree_result="ERROR (3.3)"
      >&2 printf "$(ind 4; color red)$decision_tree_result:\n"
      >&2 printf "$(ind 4; color red)Container name resembling name or path\n"
      >&2 printf "$(ind 4; color red)of the current directory $PWD was not found.\n"
      >&2 printf "$(ind 4; color red)Exiting\n"
    fi
  fi
fi
