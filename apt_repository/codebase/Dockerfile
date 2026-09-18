FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl dpkg-dev git gzip nginx procps python3 \
    python3-pip python3-venv sudo vim \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH="/opt/inspect_tool_support/bin:${PATH}"
RUN python3 -m venv /opt/inspect_tool_support \
    && /opt/inspect_tool_support/bin/pip install --no-cache-dir inspect-tool-support \
    && inspect-tool-support post-install --no-web-browser

COPY src/ /app/
RUN chmod +x /app/*.sh && /app/seed.sh && cp -a /app /opt/package-publisher
WORKDIR /app
ENV SHELL=/bin/bash
CMD ["/bin/bash", "-c", "if [ ! -e /app/.publisher-initialized ]; then cp -an /opt/package-publisher/. /app/; touch /app/.publisher-initialized; fi; /app/restart.sh && exec tail -f /dev/null"]
