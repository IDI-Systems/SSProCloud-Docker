FROM scottyhardy/docker-wine:stable-7.0

COPY install.sh /usr/bin/ssprocloud-install
COPY entrypoint.sh /usr/bin/ssprocloud-entrypoint
ENTRYPOINT ["/usr/bin/ssprocloud-entrypoint"]
