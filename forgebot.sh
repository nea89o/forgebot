#!/bin/bash
# (C) Linnea Gräf 2023 BSD 2-Clause

# Software prerequisites:
# bash
# jq
# curl
# find


function get_duration() {
    jq '.recipes[] | select(.type ="forge") | .duration * 1000' < repo/items/$1.json
}


poll_forge_events() {
    atrocity_debug "Forge polling started"
while true; do
    for uuid in $(list_all_watched_accounts); do
        if ! atrocity_is_online; then
            return
        fi
        atrocity_debug UUID: $uuid
        processes="$(curl -H "Api-Key: $HYPIXEL_KEY" https://api.hypixel.net/v2/skyblock/profiles\?uuid=$uuid 2>/dev/null | tee api_response.json|
            jq '[.profiles[] | select(.members["'$uuid'"].forge.forge_processes.forge_1) | {"qf": .members["'$uuid'"].mining_core.nodes.forge_time,"fp": [.members["'$uuid'"].forge.forge_processes.forge_1[]], cutename: .cute_name}]')"
        atrocity_debug $processes
        mkdir -p "${DATA_DIR:-.}/"notificationdata
        touch "${DATA_DIR:-.}/"notificationdata/$uuid
        now=$(date +%s000)
        rm -f "${DATA_DIR:-.}/"messagedata
        echo "$processes"| jq -r '.[] | {qf: (.qf // 0), fp: .fp[], cutename: .cutename} | (if (.qf == 20) then "0.7" elif (.qf == 0) then "1" else (1 - (.qf * .5 + 10) / 100|tostring) end) + " " + .fp.id + " " + (.fp.startTime|tostring) + " " + (.fp.slot|tostring) + " " + (.cutename)' | while read qf id starttime slot cutename; do
            atrocity_debug ID: $id STARTTIME: $starttime SLOT: $slot
            doneat=$(($starttime + $(get_duration $id)))
            atrocity_debug DONEAT WITHOUT QF: $doneat
            doneat=$(bc <<<"$starttime + $qf*$(get_duration $id)"|sed s'/\..*//')
            atrocity_debug DONE: $doneat
            already_notified=$(grep $starttime "${DATA_DIR:-.}/"notificationdata/$uuid >/dev/null; echo $?)
            atrocity_debug NOTIFIED: $already_notified
            isready=$(($now > $doneat))
            atrocity_debug "$now > $doneat: $isready"
            if [[ $isready -eq 1 ]]; then
                atrocity_debug READY 
                echo $starttime >> "${DATA_DIR:-.}/"notificationdata/$uuid.new
                if [[ already_notified -eq 1 ]]; then
                    echo Your $id in $slot on $cutename is ready since "<t:$(($doneat / 1000)):R> (started <t:$(($starttime / 1000)):R>)" >>messagedata
                    atrocity_debug ADDED
                fi
            fi
            atrocity_debug ===============================
        done
        if [[ -f messagedata ]]; then
            echo Sending messagedata: 
            atrocity_debug "$(cat "${DATA_DIR:-.}/"messagedata)"
            jsondata="$(jq -n --arg body "$(list_watchers "$uuid"|sed -E 's|(.*)|<@\1>|';echo;cat "${DATA_DIR:-.}/"messagedata)" '{"content": $body}')"
            atrocity_rest POST "channels/$CHANNEL_ID/messages" "$jsondata"
            mv "${DATA_DIR:-.}/"notificationdata/$uuid.new "${DATA_DIR:-.}/"notificationdata/$uuid
        fi
        sleep 10
    done
    sleep 300
done
}
