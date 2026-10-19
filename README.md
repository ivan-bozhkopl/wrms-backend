# wrms-backend

Backend of WRMS, the Workshop Repair Management System.

The technology stack is not chosen yet. This repository currently holds the project base: dependency
management, checks, git hooks, a container image and CI. `src/` and `tests/` contain placeholders.

## Prerequisites

- [uv](https://docs.astral.sh/uv/) `0.12.7` — the exact version is enforced by `required-version` in `pyproject.toml`:

  ```bash
  curl -LsSf https://astral.sh/uv/0.12.7/install.sh | sh
  ```

- `make` (preinstalled on most Linux distributions; on macOS it comes with the Xcode command line tools).
- Docker, to build the image.

uv installs the Python version from `.python-version` by itself.

## Quick start

```bash
make help         # list all targets
make sync         # create .venv with the project and all dev tools
make hooks        # install the git hooks (optional, local only)
make run          # run the application
```

## Checks

CI and the push hooks run these same targets:

```bash
make lint         # ruff lint and format check
make type-check   # mypy (strict)
make test         # unit tests with coverage
make lint-infra   # Dockerfile and workflows: hadolint, actionlint, zizmor
make format       # autofix lint and formatting
```

## Git hooks

Optional and local only; CI does not run them. After `make sync`:

```bash
make hooks        # install the commit and push hooks
make hooks-run    # run the commit hooks on every file
```

Commit hooks check and fix files, keep `uv.lock` current and scan for secrets. Push hooks run
`make type-check`, `make lint-infra` and `make test`. If a hook fixes a file, the commit stops: stage the change
and commit again.

## Container image

```bash
docker build -t wrms-backend .
docker run --rm wrms-backend
```

## CI

GitHub Actions runs lint, type check and infrastructure lint, then the unit tests, and builds the image alongside
them, on every pull request and push to `main`. The `CI passed` job is the single required check.
