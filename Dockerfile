FROM phusion/baseimage:jammy-1.0.1

# metadata
ARG BUILD_DATE

LABEL xyz.phyken.image.authors="hello@metaquity.xyz" \
	xyz.phyken.image.vendor="Metaquity Limited" \
	xyz.phyken.image.title="Phyken-Network/phyken" \
	xyz.phyken.image.created="${BUILD_DATE}"

# show backtraces
ENV RUST_BACKTRACE 1

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		ca-certificates && \
# apt cleanup
	apt-get autoremove -y && \
	apt-get clean && \
	find /var/lib/apt/lists/ -type f -not -name lock -delete; \
# add user and link ~/.local/share/phyken to /data
	useradd -m -u 1000 -U -s /bin/sh -d /phyken phyken && \
	mkdir -p /data /phyken/.local/share && \
	chown -R phyken:phyken /data && \
	ln -s /data /phyken/.local/share/phyken

USER phyken

# copy the compiled binary to the container
COPY --chown=phyken:phyken --chmod=774 phyken /usr/bin/phyken

# check if executable works in this container
RUN /usr/bin/phyken --version

EXPOSE 9930 9333 9944 30333 30334

CMD ["/usr/bin/phyken"]
