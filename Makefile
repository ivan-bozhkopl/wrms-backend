.DEFAULT_GOAL := help

.PHONY: help sync format lint lint-infra type-check test run

SETTINGS_FILE_NAME = pyproject.toml

help:
	@echo "-------------------- HELP --------------------"
	@grep -E "^# target:" [Mm]akefile | sed -e 's/target://'
	@echo "----------------------------------------------"

# target: Install the project (editable) and all dependency groups into .venv -> make sync
sync:
	uv sync --all-groups

# target: Format code -> make format
format:
	uv run ruff check --fix src tests
	uv run ruff format src tests

# target: Check linter -> make lint
lint:
	uv run ruff check src tests
	uv run ruff format --check --diff src tests

# target: Lint the Dockerfile and the GitHub Actions workflows -> make lint-infra
lint-infra:
	uv run hadolint Dockerfile
	uv run actionlint
	uv run zizmor --offline .github

# target: Run type check -> make type-check
type-check:
	uv run mypy --config=${SETTINGS_FILE_NAME} .

# target: Run unit tests with coverage (No infrastructure - always safe, fast feedback loop) -> make test
test:
	uv run pytest tests/unit --cov=src --cov-branch --cov-report=term-missing

# target: Run the project -> make run
run:
	uv run -m wrms_backend.main
