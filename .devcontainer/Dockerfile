# Build argument to select devbox.json variant
ARG DEVBOX_CONFIG=devbox.json

FROM jetpackio/devbox:0.16.0
WORKDIR /code
USER root:root

# Ensure devbox binary is readable and executable by all users (e.g., 1001)
RUN chmod a+rx /usr/local/bin/devbox

# Make nix-installed CLIs (kubectl, helm, etc.) available for all variants
# (dev, minimal, ops) without needing to tweak PATH at runtime.
ENV PATH="/code/.devbox/nix/profile/default/bin:${PATH}"

RUN mkdir -p /code /code/.devcontainer && chown "${DEVBOX_USER}":"${DEVBOX_USER}" /code /code/.devcontainer
USER ${DEVBOX_USER}:${DEVBOX_USER}

# Copy selected devbox config
ARG DEVBOX_CONFIG
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} ${DEVBOX_CONFIG} devbox.json
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} devbox.lock devbox.lock
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} .devcontainer/init.sh .devcontainer/init.sh
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} .devcontainer/handle-env-vars.sh .devcontainer/handle-env-vars.sh

RUN devbox install && nix-store --gc && nix-store --optimise \
    && devbox shellenv --init-hook >> ~/.profile \
    && devbox run -- /bin/sh .devcontainer/init.sh
