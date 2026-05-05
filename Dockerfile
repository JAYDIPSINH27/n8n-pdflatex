FROM node:22-bookworm-slim

USER root

# Make image smaller by avoiding docs/man pages where possible
RUN printf "path-exclude=/usr/share/doc/*\npath-exclude=/usr/share/man/*\npath-exclude=/usr/share/info/*\n" > /etc/dpkg/dpkg.cfg.d/01_nodoc

RUN apt-get update && apt-get install -y --no-install-recommends \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-font-utils \
    lmodern \
    bash \
    coreutils \
    tini \
    git \
    python3 \
    make \
    g++ \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN npm install -g n8n --omit=dev \
    && npm cache clean --force

RUN useradd -m -s /bin/bash node || true \
    && mkdir -p /home/node/.n8n \
    && chown -R node:node /home/node

USER node

WORKDIR /home/node

EXPOSE 5678

ENTRYPOINT ["tini", "--"]
CMD ["n8n"]