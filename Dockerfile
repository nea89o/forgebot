FROM alpine
RUN apk add --no-cache websocat bash jq grep curl git
COPY ./ /app/forgebot/
# Some windows systems delete the executable bit, this fixes it inside of the docker container
RUN chmod +x /app/forgebot/forgebot_proper.sh
WORKDIR "/app/forgebot"
ENTRYPOINT ["/app/forgebot/forgebot_proper.sh"]



