# Ruff

## Why ruff?
- is a Python linter and formatter written in Rust
- Advantages over alternatives like Flake8 (linting), Pylint, isort (import sorting), Black (formatting), pyupgrade (modernizing syntax):
    - 10-100x faster than pure-Python linters
    - replaces multiple alternative tools at once (implements their rules), but:
        - Pylint does deeper semantic analysis and can catch more subtle bugs, at the cost of being slower and noisier
        - does not replace type checker like mypy / pyright 

## Linting
- analyzes code to find errors, bad practices, code smells,logic issues (e.g., unused variables, undefined names)
- enforces complex coding standards

## Formatting
- ensures the code adheres to a consistent visual style (e.g., indentation, spacing, quotes)

## Installing and running ruff
- ` uv add ruff --dev`
- `uv run ruff check .` # Linting -> reports violations
    - `--fix` flag to automatically repair certain issues
- `uv run ruff format .` # Formatting
    - `--check` flag to report violations for ci pipeline

## Rule configuration
- all available rules: https://docs.astral.sh/ruff/rules/ 
- Rules activated by default: `F` ruleset (Pyflakes rules)
- the default is overridden by additional config under `[tool.ruff.lint]` in `pyproject.toml`
- Plan:
    - initially add as many rules as seem reasonable at first sight
    - using "ALL" is discouraged, because many rules are highly opinionated, experimental, or conflict with each other and because of implicit rule updates with ruff updates
    - further on, add more rules and add something like `ignore = ["E501"]` for rules that produce too much noise or that I disagree with

