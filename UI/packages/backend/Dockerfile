# This dockerfile builds an image for the backend package.
# It should be executed with the root of the repo as docker context.
#
# Before building this image, be sure to have run the following commands in the repo root:
#
# yarn install --immutable
# yarn tsc
# yarn build:backend
#
# Once the commands have been run, you can build the image using `yarn build-image`
#
# Alternatively, there is also a multi-stage Dockerfile documented here:
# https://backstage.io/docs/deployment/docker#multi-stage-build

# Stage 1: Build directory
FROM node:22-bookworm-slim AS build

# Set Python interpreter for `node-gyp` to use
ENV PYTHON=/usr/bin/python3

# Install build dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    python3=3.11.2-1+b1 \
    g++=4:12.2.0-3 \
    build-essential=12.9 \
    libsqlite3-dev=3.40.1-2+deb12u2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy files needed by Yarn
COPY --chown=node:node .yarn ./.yarn
COPY --chown=node:node .yarnrc.yml ./
COPY --chown=node:node backstage.json ./

# This switches many Node.js dependencies to production mode.
ENV NODE_ENV=production

# This disables node snapshot for Node 20 to work with the Scaffolder
ENV NODE_OPTIONS="--no-node-snapshot"

# Copy repo skeleton first, to avoid unnecessary docker cache invalidation.
# The skeleton contains the package.json of each package in the monorepo,
# and along with yarn.lock and the root package.json, that's enough to run yarn install.
COPY --chown=node:node yarn.lock package.json packages/backend/dist/skeleton.tar.gz ./
RUN tar xzf skeleton.tar.gz && rm skeleton.tar.gz

# Install dependencies
RUN --mount=type=cache,target=/home/node/.cache/yarn,sharing=locked,uid=1000,gid=1000 \
    yarn workspaces focus --all --production --check-resolutions --refresh-lockfile && rm -rf "$(yarn cache clean)"

# Copy the backend bundle
COPY --chown=node:node packages/backend/dist/bundle.tar.gz app-config.yaml ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz

# Stage 2: Runner
FROM node:22-bookworm-slim AS runner

# Install runtime dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    python3=3.11.2-1+b1 \
    libsqlite3-0=3.40.1-2+deb12u2 \
    curl=7.88.1-10+deb12u14 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy from build stage
COPY --from=build --chown=node:node /app /app

# Switch to node user
USER node

ENV NODE_ENV=production
ENV NODE_OPTIONS="--no-node-snapshot"

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl --fail http://localhost:7007/health || exit 1

CMD ["node", "packages/backend", "--config", "app-config.yaml"]
