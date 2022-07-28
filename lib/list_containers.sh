#/usr/bin/env bash

# Shows ouput of docker ps in colors:
#   Green - if contains is up,
#   Dim   - if container was stopped
#
# when --status-column argument is provided it can have the
# following arguments:
#
#     (no|off|hide) - no status at all colors will indicate
#                     it anyway)
#     short - Only the words "Up" or "Exited" will be displayed
#             (DEFAULT)
#
#     full  - just the way it is shown by the container
#             engine output.

source $BASHJAZZ_PATH/utils/colors.sh

list_containers() {

  # TODO: use CliArgs to more easily parse arguments and add other options

  local containers_list="$(docker ps -a --format "table {{.Image}}\t{{.Names}}\t{{.Status}}")"

  local running="$(echo "$containers_list" | grep '\sUp\s')"
  local stopped="$(echo "$containers_list" | grep '\sExited\s')"

  if [[ "${@}" =~ --status-column=short(\s*|$) ]]; then
    running="$(echo "$running" | sed -E "s/\s(Up).*$/\tUp /g")"
    stopped="$(echo "$stopped" | sed -E "s/\s(Exited).*$/\tExited /g")"
  elif [[ "${@}" =~ --status-column=(no|off|hide)(\s*|$) ]]; then
    running="$(echo "$running" | sed -E "s/\s(Up.*)$//g")"
    stopped="$(echo "$stopped" | sed -E "s/\s(Exited.*)$//g")"
  fi

  if [[ "${@}" =~ --image-column=name,tag(\s*|$) ]]; then
    running="$(echo "$running" | sed -E 's@^([^/]+)/([^/:]+):([^:]+)@\2:\3@g')"
    stopped="$(echo "$stopped" | sed -E 's@^([^/]+)/([^/:]+):([^:]+)@\2:\3@g')"
  elif [[ "${@}" =~ --image-column=repo,name(\s*|$) ]]; then
    running="$(echo "$running" | sed -E 's@^([^/]+)/([^/:]+)(:[^ :]*)@\1/\2@g')"
    stopped="$(echo "$stopped" | sed -E 's@^([^/]+)/([^/:]+)(:[^ :]*)@\1/\2@g')"
  elif [[ "${@}" =~ --image-column=name(\s*|$) ]]; then
    running="$(echo "$running" | sed -E 's@^([^/]+)/([^/:]+)(:[^ :]*)@\2@g')"
    stopped="$(echo "$stopped" | sed -E 's@^([^/]+)/([^/:]+)(:[^ :]*)@\2@g')"
  fi

  # Sed here replaces / and : with spaces
  local out="${Green}$running${Color_Off}\n${Dim}$stopped${Color_Off}"

  echo -e "IMAGE\tCONTAINER\n$out" | tr -s " " | column -t

}
