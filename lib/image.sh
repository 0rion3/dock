Image_extract_repo() {
  if [[ "$1" == *"/"* ]]; then
    echo "$1" | sed -E 's|^(([^/])+)/(.+)$|\1|';
  fi
}

Image_extract_name() {
  echo "$1" | sed -E "s|^(.+/)?([^:]+).*$|\2|"
}

Image_extract_tag() {
  if [[ "$1" == *":"* ]]; then
    echo "$1" | sed -E 's/^.+:([^:]*)$/\1/'
  fi
}

Image_print_info() {
  echo "repo_name=$(Image_extract_repo $1)"
  echo "image_name=$(Image_extract_name $1)"
  echo "tag_name=$(Image_extract_tag $1)"
}

Image_import_from_file() {
  image_local_path="$(echo "$1" | sed "s|^~|$HOME|")"
  is_path="$(echo "$image_local_path" | grep '\/')"
  if [[ -z $is_path ]]; then
    image_local_path="$DOCK_PATH/tmp/$image_local_path"
  fi
  if test -f "$image_local_path"; then
    while read -r line; do
      if [[ "$line" == *"Loaded image: "* ]]; then
        echo "$line" | sed -E 's/^Loaded image: //'
      fi 
    done < <(docker image load -i $image_local_path)
  else
    >&2 echo -en "$(ind 4; color red)ERROR: file "
    >&2 echo -e "$(color yellow)$image_local_path$(color red) not found$(color off)"
    exit 1
  fi
}

Image_tag() {
  docker image tag $1 $2
}

Image_rename() {
  docker image tag $1 $2
  docker rmi $1
}
