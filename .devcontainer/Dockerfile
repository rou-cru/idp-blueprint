FROM jetpackio/devbox:0.16.0

# Installing your devbox project
WORKDIR /code
USER root:root
RUN mkdir -p /code && chown "${DEVBOX_USER}":"${DEVBOX_USER}" /code
USER ${DEVBOX_USER}:${DEVBOX_USER}
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} devbox.json devbox.json
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} devbox.lock devbox.lock
# RUN devbox run -- echo "Installed Packages." && nix-store --gc && nix-store --optimise
# The nix-store commands are for optimization:
# --gc:           Garbage collects unused packages from the Nix store.
# --optimise:     Optimises the Nix store by finding identical files and hard-linking them.
RUN devbox install && nix-store --gc && nix-store --optimise
RUN devbox shellenv --init-hook >> ~/.profile
