
hypixel_request() {
  # Usage: hypixel_request <path>
  curl "https://api.hypixel.net/$1" -H "api-key: $HYPIXEL_KEY" 2>/dev/null
}

get_profiles_by_uuid() {
  # Usage: get_profiles_by_uuid <uuid>
  hypixel_request "v2/skyblock/profiles?uuid=$1"
}

