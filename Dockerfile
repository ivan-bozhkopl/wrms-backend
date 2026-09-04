# syntax=docker/dockerfile:1

ARG PYTHON_TAG=3.14-slim

FROM python:${PYTHON_TAG} AS build

COPY --from=ghcr.io/astral-sh/uv:0.12.7 /uv /usr/local/bin/uv

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV UV_PYTHON_DOWNLOADS=0

# Resolve deps first so this layer stays cached while only app code changes.
# UV_INDEX comes from the `uv_index` build secret set in release.yml; if the
# secret is absent, uv falls back to public PyPI only (same as in CI).
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=secret,id=uv_index \
    set -e; \
    if [ -f /run/secrets/uv_index ]; then export UV_INDEX="$(cat /run/secrets/uv_index)"; fi; \
    uv sync --frozen --no-dev --no-install-project --no-editable

COPY . /app

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=secret,id=uv_index \
    set -e; \
    if [ -f /run/secrets/uv_index ]; then export UV_INDEX="$(cat /run/secrets/uv_index)"; fi; \
    uv sync --frozen --no-dev --no-editable

FROM python:${PYTHON_TAG} AS runtime

WORKDIR /app
USER 65532

COPY --from=build /app /app
ENV PATH="/app/.venv/bin:${PATH}"

ENTRYPOINT []
CMD ["python", "-m", "wrms_backend.main"]
