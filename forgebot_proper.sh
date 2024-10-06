#!/bin/bash
[[ -f "$(dirname -- "$0")"/env.sh ]] && source "$(dirname -- "$0")"/env.sh
if [[ x"$ATROCITY_TOKEN" == x ]]; then
  echo "Please set ATROCITY_TOKEN to your discord token"
  exit 1
fi
if [[ x"$HYPIXEL_KEY" == x ]]; then
  echo "Please set HYPIXEL_KEY to your hypixel api key"
  exit 1
fi
source "$(dirname -- "$0")"/atrocity/load.sh
source "$(dirname -- "$0")"/hypixel_api.sh
source "$(dirname -- "$0")"/data.sh

find_option() {
  # Usage: find_option <data> <name>
  printf '%s' "$1" | jq -r '.data.options[] | select(.name == "'"$2"'")| .value'
}

disallow_mentions='"allowed_mentions": {"parse":[]}'

atrocity_on_INTERACTION_CREATE() {
  local type
  type="$(printf '%s' "$1" | jq -r .type)"
  #PING	1
  #APPLICATION_COMMAND	2
  #MESSAGE_COMPONENT	3
  #APPLICATION_COMMAND_AUTOCOMPLETE	4
  #MODAL_SUBMIT	5
  id=$(printf '%s' "$1" | jq -r .id)
  token=$(printf '%s' "$1" | jq -r .token)
  user=$(printf '%s' "$1" | jq -r .member.user.id)
  atrocity_debug Processing interaction with id $id and token $token of type $type from $user
  if [[ $type == 2 ]]; then
    command_name=$(printf '%s' "$1" | jq -r .data.name)
    atrocity_debug Executing command $command_name
    if [[ $command_name == register ]]; then
      username="$(find_option "$1" username)"
      atrocity_debug "Registering user with name $username"
      # TODO first ack then edit
      minecraft_uuid="$(curl "https://mowojang.matdoes.dev/$username" 2>/dev/null | jq -r .id)"
      atrocity_debug "Got uuid: $minecraft_uuid"
      if has_watched_account $user $minecraft_uuid; then
        atrocity_rest POST "interactions/$id/$token/callback" "$(cat << EOF
{
  "type": 4,
  "data": {
    "content": "You have already registered the account with name \`$username\` and uuid \`$minecraft_uuid\`.",
    $disallow_mentions
  }
}
EOF
        )"
      else
        add_watched_account $user $minecraft_uuid
        atrocity_rest POST "interactions/$id/$token/callback" "$(cat << EOF
{
  "type": 4,
  "data": {
    "content": "Trying to register with name \`$username\` and uuid \`$minecraft_uuid\`.",
    $disallow_mentions
  }
}
EOF
        )"
      fi
    fi
    if [[ $command_name == unregister ]]; then
      atrocity_debug "listing"
      # TODO first ack then edit
      list_watchers "$user"
    fi
    if [[ $command_name == unregister ]]; then
      username="$(find_option "$1" username)"
      atrocity_debug "Unregistering user with name $username"
      # TODO first ack then edit
      minecraft_uuid="$(curl "https://mowojang.matdoes.dev/$username" 2>/dev/null | jq -r .id)"
      atrocity_debug "Got uuid: $minecraft_uuid"
      if ! has_watched_account $user $minecraft_uuid; then
        atrocity_rest POST "interactions/$id/$token/callback" "$(cat << EOF
{
  "type": 4,
  "data": {
    "content": "You are not watching the account with name \`$username\` and uuid \`$minecraft_uuid\`.",
    $disallow_mentions
  }
}
EOF
        )"
      else
        remove_watched_account $user $minecraft_uuid
        atrocity_rest POST "interactions/$id/$token/callback" "$(cat << EOF
{
  "type": 4,
  "data": {
    "content": "Unregister the name \`$username\` and uuid \`$minecraft_uuid\`.",
    $disallow_mentions
  }
}
EOF
        )"
      fi
    fi
  fi
}
atrocity_on_unknown() {
  atrocity_debug "Skipping event $1"
}
atrocity_on_READY() {
  atrocity_debug "Payload: $1"
  user_id="$(printf '%s' "$1" | jq -r .user.id)"
  atrocity_debug "user id: $user_id"

  atrocity_rest POST applications/"$user_id"/${GUILD_EXTRA}commands "$(cat << 'EOF'
{
  "name": "register",
  "type": 1,
  "description": "Register a profile to be watched by the forge bot",
  "options": [
    {
      "name": "username",
      "description": "The Minecraft user name you want to watch",
      "type": 3
    }
  ]
}
EOF
  )"
}


atrocity_connect
atrocity_loop

