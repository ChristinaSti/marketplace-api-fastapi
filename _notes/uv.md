# uv

## installation
`curl -LsSf https://astral.sh/uv/install.sh | sh`
- L: follow redirects, -s: 	Hides progress bar and standard output., -S: Shows errors even if silenced by -s, -f: 	Fails the script if the HTTP response is an error (instead succeeding by outputting the error page)

## initial project setup
``` bash
# create a new project in your current directory or the specified <my-project> directory => adds files like `pyproject.toml and .python-version
uv init <my-project>
cd my-project
uv python pin 3.14
# add dependencies. If not created yet, it also creates a virtual env at .venv. It also installs the packages unless you add `--no-sync` flag. No need for subsequent `uv sync`.
uv add fastapi uvicorn 
# add dependencies for development only
uv add pytest ruff --dev
# if you added dependency to pyproject.toml by hand, install dependencies using:
uv sync
# start the app:
uv run uvicorn app.main:app --reload
```
## ci commands
``` bash
uv run pytest  
uv run ruff check . (--fix)
(uv run ruff format (--check .))
```

# what to add to .gitignore and what not:
- DON'T ADD:
    - .venv: the virtual environment
        - why: it is large, platform-specific and fully reproducible from the lockfile via uv sync
- ADD:
    - `.python-version`: pins the Python version for everyone working on the project across environments
    - `uv.lock`: records the exact **resolved** versions of every dependency (including transitive ones) across all platforms
        - => Reproducible, deterministic installs for everyone
    - `pyproject.toml`: Project metadata and declared dependencies (loose, human-authored, expresses intent)