# The site image: the presentation site (plain HTML in this directory) served by nginx at velomine.eu. Only the public
# demo host runs it (compose.site.yaml); a self-hosted Velomine has no use for it. Built with this directory as the
# context, and it has no smoke test: the site is static and rarely changes.
FROM nginx:1.30.6-alpine@sha256:583b7f2fce1cdb8da5ad5c39ebd3c33b98b87d493190e548bdee1fa8c619c311
ARG VERSION=0.0.0
ARG REVISION=unknown
COPY nginx.conf /etc/nginx/nginx.conf
COPY . /srv/site
# The build files are not part of the site.
RUN rm /srv/site/Dockerfile /srv/site/nginx.conf
LABEL org.opencontainers.image.title="Velomine site" \
      org.opencontainers.image.description="Velomine presentation site" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.source="https://github.com/zenkraker/Velomine"
USER nginx
EXPOSE 8080
STOPSIGNAL SIGQUIT
# nginx directly, without the image's entrypoint scripts: they rewrite files the read-only root does not allow.
ENTRYPOINT ["nginx", "-g", "daemon off;"]
