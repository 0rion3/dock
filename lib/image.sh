Image_extract_repo() {
  if [[ "$1" == *"/"* ]]; then
    echo "$1" | sed -E 's|^(([^/])+)/(.+)$|\1|';
  fi
}

# Requires repo name as a second argument
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
