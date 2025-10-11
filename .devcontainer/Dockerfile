# Build argument to select devbox.json variant
ARG DEVBOX_CONFIG=devbox.json

FROM jetpackio/devbox:0.16.0
WORKDIR /code
USER root:root

RUN mkdir -p /code && chown "${DEVBOX_USER}":"${DEVBOX_USER}" /code
RUN mkdir -p /code/.devcontainer && chown "${DEVBOX_USER}":"${DEVBOX_USER}" /code/.devcontainer
USER ${DEVBOX_USER}:${DEVBOX_USER}

# Copy selected devbox config
ARG DEVBOX_CONFIG
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} ${DEVBOX_CONFIG} devbox.json
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} devbox.lock devbox.lock
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} .devcontainer/init.sh .devcontainer/init.sh
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} .devcontainer/handle-env-vars.sh .devcontainer/handle-env-vars.sh

RUN devbox install && nix-store --gc && nix-store --optimise

ENV PATH="/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:${PATH}"
RUN devbox shellenv --init-hook >> ~/.profile

# Pre-initialize helm repos and environment
RUN devbox run -- /bin/sh .devcontainer/init.sh