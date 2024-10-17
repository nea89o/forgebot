export FORGEBOT_DATA_DIR="${DATA_DIR:-.}/forgebotdata"
mkdir -p "$FORGEBOT_DATA_DIR" 

list_all_watched_accounts() {
  grep --files-with-matches -rE '.*' "$FORGEBOT_DATA_DIR" | sed s'|.*/||'
}

list_watchers() {
  # Usage: list_watchers <minecraft uuid>
  cat "$FORGEBOT_DATA_DIR/$1"
}

find_watched_accounts() {
  # Usage: find_watched_accounts <discord uuid>
  grep -lr "$1" "$FORGEBOT_DATA_DIR" | sed 's|.*/||'
}

add_watched_account() {
  # Usage: add_watched_account <discord uuid> <minecraft uuid>
  echo "$1" >> "$FORGEBOT_DATA_DIR/$2"
}

remove_watched_account() {
  # Usage: remove_watched_account <discord uuid> <minecraft uuid>
  sed -i "/$1/d" "$FORGEBOT_DATA_DIR/$2"
}

has_watched_account() {
  # Usage: has_watched_account <discord uuid> <minecraft uuid>
  grep "$1" "$FORGEBOT_DATA_DIR/$2" >/dev/null
  return $?
}



