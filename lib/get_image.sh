source $DOCK_PATH/lib/image.sh
source $BASHJAZZ_PATH/utils/array.sh

declare -A image_set
declare -a image_aliases

GetImage_import() {
  local name="$1"
  local source_type="${2:-hub}"
  case $source_type in
    url)    GetImage_from_url          $name;;
    magnet) GetImage_print_magnet_link $name;;
    hub)    GetImage_from_hub          $name;;
    file)   GetImage_from_file         $name;;
  esac
}

GetImage_remote_aliases() {
  echo "$(echo "${image_aliases[@]}" | sed -E 's/,?[ \t]+/,/g' | xargs)"
}

GetImage_print_remote_list() {
  echo -e "$(ind 4; color dim)List of official dock-compatible remote images:$(color off)\n"
  local i=1
  for alias_line in "${image_aliases[@]}"; do
    alias_line="$(echo "$alias_line" | sed 's/,/ /g')"
    local last_alias="$(echo "$alias_line" | grep -oE '[^ ]+$')"
    local aliases_before_last="$(echo "$alias_line" | sed -E "s|$last_alias||")"
    echo -e "$(ind 8)$i. $aliases_before_last$(color blue)$last_alias$(color off)"
    ((i+=1))
  done

  printf "\n"

  echo -e "$(ind 4; color dim)To download and/or import one, use either one of these commands:"
  echo -e "$(ind 4)(these examples are given for the first, default image):$(color off)"
  echo -e "$(ind 8; color yellow)\$ $(color off)dock -c image import 1"
  echo -e "$(ind 8; color yellow)\$ $(color off)dock -c image import default"
  echo -e "$(ind 8; color yellow)\$ $(color off)dock -c image import ubuntu20"
  echo -e "$(ind 8; color yellow)\$ $(color off)dock -c image import dock/ubuntu20:stable"
}

GetImage_print_magnet_link() {
  local link="$(GetImage_link_for $1 magnet)"
  echo -e "\n$(ind 4)Use the magnet link below to get the image via BitTorrent."
  echo -e "$(ind 4)When it's done, retry the command and provide path to the downloaded filename."
  echo -e "$(ind 4)And please also seed this torrent too, if you can."
  echo -e "\n$(ind 4; color blue)$link$(color off; color dim)\n"
}

GetImage_from_url() {
  local url="$(GetImage_link_for "$1" url)"
  fn="$(echo "$url" | grep -oE '[^/]+$' | sed 's|[^A-Za-z0-9_.-]||g')"
  echo -e  "$(ind 8; color off)Downloading image directly from"
  echo -en "$(ind 12; color blue)"
  echo -e  "$url"
  echo -e  "$(color off; ind 8)Please wait until the download is complete.$(color dim)\n"
  curl $url -o $DOCK_PATH/tmp/$fn
  printf "\n"
  GetImage_from_file $DOCK_PATH/tmp/$fn
}

GetImage_from_file() {
  local fn="$1"
  local source_name=$(Image_import_from_file "$fn")
  if [[ -n "$source_name" ]]; then
    local target_name=$(GetImage_target_name "$source_name")
    GetImage_tag_after_download $source_name $target_name
  else
    echo -e "$(color red; ind 4)ERROR: something went wrong."
    echo -e "$(color off; ind 8)\($source_name\)"
  fi
}

GetImage_from_hub() {
  local name="$1"
  local hub_name="$(GetImage_link_for $1 hub)"
  hub_name="${hub_name:-$name}"

  local target_name="$(GetImage_target_name $name)"

  echo -e "$(ind 4)Pulling $hub_name from Docker Hub..."
  echo -e "$(color gray)$(docker image pull $hub_name)$(color off; color dim)\n" |\
    sed "s/^/$(ind 8)/g"

  GetImage_tag_after_download $hub_name $target_name
}

GetImage_tag_after_download() {
  local source_name="$1"
  local target_name="$2"
  if [[ -n "$target_name" ]] && [[ "$source_name" != "$target_name" ]]; then
    Image_tag $source_name $target_name > /dev/null
    declare -g image_full_name="$target_name"
    echo -en "$(ind 4)Tagged image $(color blue)$source_name$(color off)"
    echo -e  "$(color dim) as $(color green)$target_name$(color off; color dim)"
  else
    declare -g image_full_name="$source_name"
  fi
}

# Target name is the name into which the imported image will be renamed.
# This happens only if the original $name provided by the user as the argument
# to the caller script is present somewhere in the $remote_image_list_file
# alias lines. We then pick the last part of that line after the space
# character and that becomes the target name.
GetImage_target_name() {
  for alias_line in "${image_aliases[@]}"; do
    alias_line=( $(echo "$alias_line" | sed 's/,/ /g') )
    if [[ -n "$(Array_contains $1 ${alias_line[@]})" ]]; then
      echo "${alias_line[-1]}"
      break;
    fi
  done
}

GetImage_all_links_for() {
  for k in "${!image_set[@]}"; do
    if [[ -n "$(Array_contains $1 $k)" ]]; then
      local img_aliases_line="$k"
      break;
    fi
  done
  if [[ -z "$img_aliases_line" ]]; then exit 1; fi
  # Return all links separated by spaces
  echo "${image_set["$img_aliases_line"]}" | xargs
}

GetImage_link_for() {
  local name=$1
  local link_type=$2
  local links="$(GetImage_all_links_for $name)"
  case $link_type in
    url)    echo "${links[@]}" | grep -oE '(^| +)https?:[^ ]+( |$)' | xargs;;
    magnet) echo "${links[@]}" | grep -oE '(^| +)magnet:[^ ]+( |$)' | xargs;;
    hub)    echo "${links[@]}" | grep -oE '(^| +)[^ ]+( |$)' | grep -Ev '(magnet|https?):' | xargs;;
  esac
}

GetImage_remote_list() {

  if [[ -n "$image_set" ]]; then return 0; fi

  function fetch_file() {
    if [[ -z "$remote_image_list_file" ]]; then
      # We download it into a file, because otherwise the script will
      # will not be waiting for curl to finish, which may result in empty
      # output.
      if curl --silent $DOCK_URL/images.txt -o $DOCK_PATH/remote_images.txt.tmp; then
        remote_image_list_file="$(cat $DOCK_PATH/remote_images.txt.tmp | grep -vE '^[ \t]*#+')"
        rm $DOCK_PATH/remote_images.txt.tmp
      fi
    fi
    echo "$remote_image_list_file"
  }

  local new_block=1;
  local current_alias_line
  local links;

  while IFS= read -r line; do
    if [[ -z "$line" ]]; then
      new_block=1
    else
      if [[ -n $new_block ]]; then
        current_alias_line="$line"
        image_aliases="$image_aliases $(echo "$line" | sed -E 's/[ \t]+/,/g')"
        # item1: hub, item2: url, item3: magnet
        # If you want anyone of them empty with the next non-empty item,
        # use NO_HUB, NO_URL or NO_MAGNET respectively.
        unset links;
        unset new_block;
      else
        links="$links $line"
        image_set["$current_alias_line"]="$links"
      fi
    fi
  done < <(fetch_file)

  image_aliases=( $image_aliases )

}
