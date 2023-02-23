source $BASHJAZZ_PATH/utils/formatting.sh

Container_exec() {
  local OPTIND
  local encode;
  local user;
  while getopts "u:e" opt; do
    case $opt in
      # Encoded command with base 64, the container will decode and run it.
      # This is for complex cases when commands are rather long with lots of chars
      # and it gets to be a pain in the as to escape them or tune it all such that it works.
      e) local encode=1;;
      u) local user=$OPTARG;;
    esac
    shift $((OPTIND-1))
  done

  user=${user:-root}
  if [[ -n $encode ]]; then
    cmd="$($BASHJAZZ_PATH/utils/base64_exec $1)"
    docker exec -u $user $container_name /usr/local/share/host_provided/scripts/base64_exec $cmd
  else
    # Use login shell (-l), this way $HOME/.bashrc is sourced.
    docker exec -u $user $container_name bash -l -c "${@}"
  fi
}

Container_update_ssh_keys() {

  function print_error() {
    >&2 echo -e  "$(color red; ind 4)ERROR: cannot proceed with connection to the container without ssh keys$(color off)"
    >&2 echo -e  "$(ind 4)Please generate public/private key pair yourself."
    >&2 echo -e  "$(ind 4)Place them inside your $(color blue)~/.ssh/$(color off) directory,"
    >&2 echo -en "$(ind 4)naming private and public keys $(color blue)${dock_network}_host$(color off) and "
    >&2 echo -e  "$(color blue)${dock_network}_host.pub $(color off)respectively.\n"
    exit 1
  }

  if [ ! -f $HOME/.ssh/${dock_network}_host ]; then
    echo -e  "\n$(ind 2; color yellow)No public/private pair of ssh keys were found: ~/.ssh/${dock_network}_host(.pub)"
    echo -en "$(ind 2;)Would you like to generate the keypairs now? (y/n):$(color off) "
    read answer
    if [[ $answer == "y" ]]; then
      echo ""
      time_suffix=$(date +"%T.%N" | sed 's/[^0-9]//g')
      ssh-keygen -t ed25519 \
        -C "dockhost_$(whoami)@$(hostnamectl --static)_$time_suffix" -f $HOME/.ssh/${dock_network}_host || print_error
    else
      print_error
    fi
  fi

  ssh_pubkey=$(cat $HOME/.ssh/${dock_network}_host.pub)
  root_ssh_key=$(Container_exec "grep -qsxF '$ssh_pubkey' /root/.ssh/authorized_keys || echo nokey")
  docker_ssh_key=$(Container_exec "grep -qsxF '$ssh_pubkey' /home/docker/.ssh/authorized_keys || echo nokey")
  if [[ "$root_ssh_key" == "nokey" ]]; then
    Container_exec "echo '$ssh_pubkey' >> /root/.ssh/authorized_keys"
    echo -e "$(ind 2)Imported ~/.ssh/${dock_network}_host.pub into containers /root/.ssh/authorized_keys"
  fi
  if [[ "$docker_ssh_key" == "nokey" ]]; then
    Container_exec -u docker "echo '$ssh_pubkey' >> /home/docker/.ssh/authorized_keys"
    echo -e "$(ind 2)Imported ~/.ssh/${dock_network}_host.pub into containers /home/docker/.ssh/authorized_keys"
  fi

  # Just ensuring all directories have correct permissions,
  # this might have changed for various reasons.
  Container_exec \
  "chown -R docker /home/docker/.ssh/          && \
   chgrp -R docker /home/docker/.ssh/          && \
   chmod 700 /home/docker/.ssh                 && \
   chmod 700 /root/.ssh/                       && \
   chmod 600 /home/docker/.ssh/authorized_keys && \
   chmod 600 /root/.ssh/authorized_keys"

}


# Add host ip address to /etc/hosts (unless it's already there)
Container_update_etc_hosts() {
  # adding 1 in the end, because that would always be our
  # host's machine ip address on the created network.
  host_ip="$(docker network inspect $dock_network | grep "Gateway" | grep -oE '([0-9]{1,3}\.){3}')1"
  etc_hosts_docker_host_record="$host_ip dockhost"

  docker exec $container_name bash -c \
    "grep -qxF '$etc_hosts_docker_host_record' /etc/hosts || \
    echo '$etc_hosts_docker_host_record' >> /etc/hosts"
}

# This function is deprecated. OpenSSH server is started in
# /root/dock_bin/startup_jobs.
Container_start_sshd() {
  # Only start if not running
  sshd_running="$(docker exec $container_name bash -c 'ps aux | grep [s]sh')"
  if [[ -z $sshd_running ]]; then
    docker exec $container_name bash -c 'service ssh start'
    echo -e "$(ind 4)Starting sshd service from host via docker exec..."
  fi
}

Container_startup_jobs() {
  Container_update_etc_hosts
  Container_exec \
    'test -f /root/dock_bin/startup_jobs && /root/dock_bin/startup_jobs'
  Container_exec -u docker \
    'test -f /home/docker/dock_bin/startup_jobs && /home/docker/dock_bin/startup_jobs'
}

Container_connection_jobs() {
  Container_update_ssh_keys
  Container_exec \
    'test -f /root/dock_bin/connection_jobs && /root/dock_bin/connection_jobs'
  Container_exec -u docker \
    'test -f /home/docker/dock_bin/connection_jobs && /home/docker/dock_bin/connection_jobs'
}

Container_info() {
  local format='container_id="{{.ID}}",container_name="{{.Names}}",container_image_name="{{.Image}}"'
  local format="$format,container_status=\"{{.Status}}\""
  docker container list --all --format "$format" | grep "container_name=\"$1\""
  # The second line is necessary because the first docker command above one
  # wouldn't allow us to look up that information.
  echo $(Container_image_name)
}

Container_ip_address() {
  # When container is started, we need to wait a bit before its network
  # connections starts working and ip address is assigned so we basically try
  # 5 times, each second.
  local ip
  local attempts=$(($1))
  i=0

  while [ $i -le $attempts ] && [[ -z $ip ]]; do
    ip=$(docker container inspect -f \
      "{{ .NetworkSettings.Networks.$dock_network.IPAddress }}" $container_name 2> /dev/null)
    i=$((i+1))
    sleep 1
  done

  if [[ -n "$ip" ]]; then
    echo $ip
  else
    >&2 echo -e "$(color red; ind 4)ERROR: unable to fetch container's ip address after $1 attempts."
    >&2 echo -e "$(color red; ind 4)       please check whether it's actually running or the network is set up correctly."
    exit 1
  fi
}

Container_image_name() {
  docker container inspect -f "{{ .Config.Image }}" $container_name 2> /dev/null
}

Container_rm_path() {

  if [[ "$2" == "DIR" ]]; then
    rm_cmd='rm -rf'
    _type="[DIR] "
  else
    rm_cmd='rm'
    _type="[FILE]"
  fi

  not_found_msg="$(echo -e "$(color dim; ind 4)$_type (not found) $1$(color off)")"
  success_msg="$(echo -e "$(color dim; ind 4)$_type $(ind 4) $rm_cmd $(color red)$1$(color off)")"

  docker exec $container_name bash -c "($rm_cmd $1 2> /dev/null) && echo '$success_msg' || echo '$not_found_msg'"
}

# Works only with Ubuntu/Debian containers and its apt-get package-manager for now
# and will do nothing if apt-get isn't found inside the container
Container_package_cache_paths() {
  echo "$(Container_exec "apt-get clean --dry-run")" | sed 's/Del //g' | xargs
}

# This just prints what's in $container_name. Currently it's more for
# debugging purposes, so we're always sure it's the right container.
Container_current_name() {
  echo $container_name
}
