.DEFAULT_GOAL := help

.PHONY: help sync install-dev format lint type-check secure test run

SETTINGS_FILE_NAME = pyproject.toml

help:
	@echo "-------------------- HELP --------------------"
	@egrep "^# target:" [Mm]akefile | sed -e 's/target://'
	@echo "----------------------------------------------"

# target: Sync the project with the latest dependencies without installing the project itself -> make sync
sync:
	uv sync --all-groups

# target: Install the project using symlinks (for development) -> make install-dev
install-dev:
	uv sync --all-groups
	uv pip install -e .

# target: Format code -> make format
format:
	uv run ruff check --fix src tests
	uv run ruff format src tests

# target: Check linter -> make lint
lint:
	uv run ruff check src tests
	uv run ruff format --check --diff src tests

# target: Run type check -> make type-check
type-check:
	uv run mypy --config=${SETTINGS_FILE_NAME} .

# target: Run all security related checks -> make secure
secure:
	uv run bandit -r src --config=${SETTINGS_FILE_NAME}

# target: Test the project (No infrastructure - always safe, fast feedback loop) -> make test
test:
	uv run pytest

# target: Run the project -> make run
run:
	uv run -m wrms_backend.main
