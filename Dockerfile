FROM alpine:3.22.1
RUN apk add --update --no-cache curl
COPY target/install.sh /
RUN sh /install.sh && rm /install.sh
ENTRYPOINT [ "/opt/bin/shelduck" ]