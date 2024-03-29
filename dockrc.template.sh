#!/usr/bin/env bash

DOCK_PATH="$HOME/[path/to/dock/directory/which/you/downloaded]"
DOCK_NETWORK_NAME="dock0"
IGNORED_PREFIX_PATH="$HOME"
DEFAULT_REPO_NAME="dock"
DEFAULT_IMAGE_NAME="ubuntu20"
DEFAULT_IMAGE_TAG_NAME="stable"
DEFAULT_IMAGE_FULL_NAME="$DEFAULT_REPO_NAME/$DEFAULT_IMAGE_NAME:$DEFAULT_IMAGE_TAG_NAME"
BASHJAZZ_PATH="$DOCK_PATH/vendor/bashjazz"

DOCKER_RUN_OPTS=''
# useful on Windows with WSL2/Docker Desktop (may be MacOs too?) where Docker lives in different VM
#DOCKER_RUN_OPTS='--expose 22 -P '


# Syntax (if you haven't read through Docker documentation):
# [HOST_PATH]:[GUEST_PATH]:[flags]
# flags are usually `ro` or `rw` (read-only) or (read-write).
#
# One of the default mounts is the ~/Public/dock-share directory
# mounted into every container, so you can easily place the files you want
# to transfer into the container there. It's mounted in read-only mode
# and, of course, you can remove it from here too. Or, if the directory
# doesn't exist, then it won't be mounted anyway.
#
# It is advised not to remove $BASHJAZZ_PATH/* mounts, because even in the case
# of a base image, they are used in multiple places to, for example,
# format the output you see or determine the shell currently running -
# which may be important and useful. The container will work without these,
# but, most likely it will be less pretty when you connect to and
# less convenient to work with in general.
DEFAULT_MOUNT_OPTIONS="
  -v $HOME/Public/dock-share:/home/docker/host-shared:ro
  -v $BASHJAZZ_PATH/utils:/usr/local/bashjazz/utils:ro
  -v $BASHJAZZ_PATH/network:/usr/local/bashjazz/network:ro"

# This will be used as the first part of the ip address, so that the
# $ASSIGNED_IP_ADDRESSES associative array doesn't look too long and is easier
# to read. It's usually 172.17.0 for the default docker network, but we'd want
# a different network for all of our dock-based containers.  If you haven't
# done so yet, create a network bridge with this command:
#
#  $ docker network create dock0
#
DOCK_SUBNET="172.18.0"
# notice the last part of the ip address is intentionally missing.
# It will be assigned below in the $ASSIGNED_IP_ADDRESSES variable
# and later added to the $DOCK_SUBNET. And if ASSIGNED_IP_ADDRESS
# for a specific container name is not in found in the ASSIGNED_IP_ADDRESS
# the next available one (starting from 2 and up) will be used.
#
declare -A ASSIGNED_IP_ADDRESSES=( \
  [container.nameA]=24             \
  [container.nameB]=23             \
  [container.nameC]=22             \
)

# Your terminal can change colors automatically as you ssh into the Docker guest.
# The default theme will be assigned to "Dockguest" for user docker
# and to $TERMINAL_ROOT_THEME for user "root" (see below) unless a match for
# the container name is found in this associative array. If you connect as user
# "root" (dock -r), then $TERMINAL_ROOT_THEME will be used regardless -
# unless it's intentionally set to empty or commented out.
#
# THIS FUNCTIONALITY REQUIRES YOUR TERMINAL EMULATOR INTEGRATION AND SOME MANUAL
# ACTION ON YOUR PART IN ORDER FOR IT TO WORK. Please read 
# documentation in $DOCK_HOME/documentation/TERMINALS.txt
#
declare -A TERMINAL_THEMES=(  \
 [container.nameA]=Dockguest1 \
 [container.nameB]=Dockguest2 \
 [container.nameC]=Dockguest3 \
)

# Whenever you connect as root (dock -r) you this will be the default theme.
TERMINAL_ROOT_THEME="DockguestRoot"

declare -A TERMINAL_ROOT_THEMES=(  \
 [container.nameA]=DockRoot1 \
 [container.nameB]=DockRoot2 \
 [container.nameC]=DockRoot3 \
)

# Annoyed by the welcome message? Disable it.
# Unfortunately, it currently disables it for ALL containers,
# not just the ones you're already working with, because the idea
# of a welcome message is to quickly get the user up to speed with
# what's inside the image without making him read tons of documentation.
#
#DISABLE_DOCK_WELCOME_MESSAGE=1

# Official site, form which images and some other things MAY be downloaded.
# For Docker Images - Docker Hub will be attempted first, though.
# But this is still needed by the $DOCK_PATH/bin/get-image command to pull
# the list of dock-compatible images. This address may change. As `dock`
# is updated, it will notify you when these changes are needed, although this
# kind of change should be very very rate.
DOCK_URL="https://dock.orion3.space"
