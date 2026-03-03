FROM --platform=linux/amd64 alpine:3.19
RUN apk add --no-cache curl
COPY monitor.sh /monitor.sh
RUN chmod +x /monitor.sh
ENTRYPOINT ["/monitor.sh"]
