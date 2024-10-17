FROM alpine
RUN apk add --no-cache websocat bash jq grep curl git
COPY ./ /app/forgebot/
WORKDIR "/app/forgebot"
ENTRYPOINT ["/app/forgebot/forgebot_proper.sh"]



