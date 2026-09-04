# syntax=docker/dockerfile:1

# The digests pin the exact images; the tags next to them are for readability and
# play no part in resolution. uv.lock pins the Python packages, these two pin the
# interpreter and the OS underneath it.
ARG PYTHON_TAG=3.14.7-slim-trixie@sha256:cad9a2c871761c413caa6fdd6441c783451e740a48aaeba60ae62a8b53525ef6
ARG UV_TAG=0.12.7@sha256:95f2aa1fe59274951cfe9b0cbc7972e879ff1004bc8945d130a32eb0dbd85945

# uv is a single static binary, so it is taken from its own image as a file.
FROM ghcr.io/astral-sh/uv:${UV_TAG} AS uv

FROM python:${PYTHON_TAG} AS build

COPY --from=uv /uv /usr/local/bin/uv

WORKDIR /app

# Compile .pyc during install so startup does not pay for it on first import.
ENV UV_COMPILE_BYTECODE=1
# The uv cache below is a separate mount, and hardlinks cannot cross filesystems.
ENV UV_LINK_MODE=copy
# Use the interpreter from the base image instead of fetching a standalone one.
ENV UV_PYTHON_DOWNLOADS=0

# Dependencies follow from uv.lock and pyproject.toml alone, so this layer stays
# cached until one of them changes. Both are bind-mounted because they are only
# needed while the command runs, not afterwards in the layer.
#
# UV_INDEX is a private index URL carrying credentials, so it arrives as a build
# secret mounted on tmpfs and never reaches a layer. It is optional: an unset
# secret shows up as an empty file, which leaves uv resolving against public PyPI.
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=secret,id=uv_index \
    set -e; \
    if [ -s /run/secrets/uv_index ]; then export UV_INDEX="$(cat /run/secrets/uv_index)"; fi; \
    uv sync --locked --no-dev --no-install-project --no-editable

# Just the build backend's inputs, so changes to tests, CI config or docs leave
# the layers below untouched. README.md belongs here because [project] declares
# it as the readme and uv_build embeds it in the wheel metadata.
COPY pyproject.toml uv.lock README.md ./
COPY src ./src

# The sources are in place, so this pass installs the project itself.
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=secret,id=uv_index \
    set -e; \
    if [ -s /run/secrets/uv_index ]; then export UV_INDEX="$(cat /run/secrets/uv_index)"; fi; \
    uv sync --locked --no-dev --no-editable

FROM python:${PYTHON_TAG} AS runtime

# The account the service runs under. 65532 is the conventional nonroot UID/GID;
# the passwd entry gives it a resolvable name for pwd lookups and a real $HOME.
RUN groupadd --gid 65532 nonroot \
 && useradd --uid 65532 --gid 65532 --create-home --home-dir /home/nonroot \
            --shell /usr/sbin/nologin nonroot

# Container stdout is not a TTY, so Python would block-buffer it and logs would
# surface late or vanish when the process is killed.
ENV PYTHONUNBUFFERED=1
# Putting the venv first is what activating it amounts to inside an image.
ENV PATH="/app/.venv/bin:${PATH}"

WORKDIR /app

# --no-editable installed the package as a real copy inside the venv, so the venv
# is the entire runtime artefact. It stays owned by root: the service reads and
# executes its own code but cannot rewrite it.
COPY --from=build /app/.venv /app/.venv

USER 65532:65532

# Exec form, so python runs as PID 1 and receives SIGTERM directly on shutdown.
ENTRYPOINT []
CMD ["python", "-m", "wrms_backend.main"]
