#!/bin/bash
# (C) Linnea Gräf 2023 BSD 2-Clause

# Software prerequisites:
# bash
# jq
# curl
# find


# Configuration:

# Your hypixel api key
API_KEY="81420b47-17db-44ed-aee0-f15662d650f0"
# Your discord webhook url
WEBHOOK_URL="https://discord.com/api/webhooks/1137392560973828107/6MmpfsLcIN9S9Xp1LlmPD56EF_QRD-W4JvbUwShXdP-_A_paDoGCAlaRfIQxgsRDZzq5"

# Now create a folder called forgebotdata. In that folder create a file for every user, with the name being their uuid without dashes, and the content being their discord id:
#
# forgebot.sh
# forgebotdata/
# forgebotdata/4154a5602654493094d3497d2ad6849f: 281489313840103426
# forgebotdata/d3cb85e2307548a1b213a9bfb62360c1: 310702108997320705
#

function get_duration() {
    jq '.recipes[] | select(.type ="forge") | .duration * 1000' < repo/items/$1.json
}


while true; do
    for uuid in $(find forgebotdata -type f); do
        discordid=$(cat $uuid)
        uuid=${uuid#forgebotdata/}
        echo UUID: $uuid
        processes="$(curl -H "Api-Key: $API_KEY" https://api.hypixel.net/skyblock/profiles\?uuid=$uuid 2>/dev/null | 
            jq '[.profiles[].members["'$uuid'"] | select(.forge.forge_processes.forge_1) | {"qf": .mining_core.nodes.forge_time,"fp": [.forge.forge_processes.forge_1[]]}]')"
        echo $processes
        mkdir -p notificationdata
        touch notificationdata/$uuid
        now=$(date +%s000)
        rm -f messagedata
        echo "$processes"| jq -r '.[] | {qf: .qf, fp: .fp[]} | (if (.qf == 20) then "0.7" elif (.qf == 0) then "1" else (1 - (.qf * .5 + 10) / 100|tostring) end) + " " + .fp.id + " " + (.fp.startTime|tostring) + " " + (.fp.slot|tostring)' | while read qf id starttime slot; do
            echo ID: $id STARTTIME: $starttime SLOT: $slot
            doneat=$(($starttime + $(get_duration $id)))
            echo DONEAT WITHOUT QF: $doneat
            doneat=$(bc <<<"$starttime + $qf*$(get_duration $id)"|sed s'/\..*//')
            echo DONE: $doneat
            already_notified=$(grep $starttime notificationdata/$uuid >/dev/null; echo $?)
            echo NOTIFIED: $already_notified
            isready=$(($now > $doneat))
            echo "$now > $doneat: $isready"
            if [[ $isready -eq 1 ]]; then
                echo READY 
                echo $starttime > notificationdata/$uuid.new
                if [[ already_notified -eq 1 ]]; then
                    echo Your $id in $slot is ready since "<t:$(($doneat / 1000)):R> (started <t:$(($starttime / 1000)):R>)" >>messagedata
                fi
            fi
        done
        if [[ -f messagedata ]]; then
            echo Sending messagedata: 
            cat messagedata
            jsondata="$(jq -n --arg body "$(printf '<@%s>\n%s' $discordid "$(cat messagedata)")" '{"content": $body, "username": "Forgebot"}')"
            curl -X POST "$WEBHOOK_URL" -H "Content-Type: multipart/form-data" -F "payload_json=$jsondata"
            mv notificationdata/$uuid.new notificationdata/$uuid
        fi
        sleep 10
    done
    sleep 300
done
