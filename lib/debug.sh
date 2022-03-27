#!/usr/bin/env bash
source $BASHJAZZ_PATH/utils/formatting.sh

case $1 in
  main)
    echo -e "${Gray}"
    echo "------------------------------------------------------------"
    echo "[DEBUG] DIRECTORY VARIABLES"
    echo "$directory_info"
    echo "------------------------------------------------------------"
    echo "[DEBUG] IMAGE VARIABLES"
    echo "   These may not influence anything if a container"
    echo "   is already running."
    echo "$image_info"
    echo "------------------------------------------------------------"
    echo "[DEBUG] PROJECT VARIABLES"
    echo "$project_info"
    echo "------------------------------------------------------------"
    echo "[DEBUG] CONTAINER VARIABLES"
    echo "container_image_name=$container_image_name"
    echo "container_ip_addr=$container_ip_addr"
    echo "------------------------------------------------------------"
    echo "[DEBUG] The decision tree result: $decision_tree_result"
    echo "        (see documentation/DECISION_TREE.txt and report any"
    echo "        inconsistencies or deviations from it)."
    echo -e "${Color_Off}"
    ;;
  ssh)
    echo -e "${Gray}"
    echo "------------------------------------------------------------"
    echo "[DEBUG] SSH connection info"
    echo "    container ip address: $container_ip_addr"
    echo ""
    echo "[DEBUG] TEMPORARY ssh config file contents:"
    cat $HOME/.ssh/$2
    echo -e "${Color_Off}"
    ;;
esac
