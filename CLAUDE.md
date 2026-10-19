# CLAUDE.md — wrms-backend

## What this repo is

The backend of WRMS, the Workshop Repair Management System. The technology stack is not chosen yet: the repository
holds only the project base, and `src/` and `tests/` are placeholders. Do not add frameworks, a database or
application layers without asking.

## Commands

Use `make` targets, never call ruff/mypy/pytest directly (CI calls the same targets). `make help` lists them.

- `make sync` installs everything into `.venv`; `make format` autofixes.
- Checks: `make lint`, `make type-check`, `make test`, and `make lint-infra` for the Dockerfile and the workflows.
- Run Python tooling through `uv run`. Never `pip install`. Change dependencies with `uv add [--group <group>]`
  or `uv lock`, never by editing `uv.lock`.

## Definition of done

Before saying a change is finished, or before committing, run the checks that match what you touched:

- Python, config or `pyproject.toml`: `make lint && make type-check && make test`.
- `.github/**` or `Dockerfile`: `make lint-infra`.
- `Dockerfile`: `docker build .` if Docker is available; otherwise say it was not verified.

Do not rely on git hooks for this. They are optional, installed per clone with `make hooks`, and pre-push
hooks run only on push. If a commit hook modifies files, the commit stops: `git add` the changes and commit again.
Never use `--no-verify`. Report failures as they are; do not claim a check passed unless you ran it.

## Git workflow

- Do not commit to `main`. Every change goes on a feature branch named `<type>/<slug>`: `feat`, `fix`, `docs`,
  `ci`, `build`, `refactor`, `chore`.
- Conventional Commits with an optional scope: `ci: ...`, `build(docker): ...`, `docs: ...`.
  Small, focused commits, each describing one logical change: they land on `main` as they are, not squashed.
- Changes reach `main` only through a pull request, merged on GitHub after `CI passed` is green. The merge method
  is a merge commit (not squash or rebase), so the branch's commits and the point where it joined `main` stay in
  the history. Never merge into `main` locally.
