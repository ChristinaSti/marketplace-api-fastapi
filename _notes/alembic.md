# Alembic
- is a database schema migration tool for Python, most commonly used with SQLAlchemy
## Why use Alembic
- tracks schema changes in versioned migration files
- reproducible, ordered history of changes helps team collaboration
- Safe Upgrades & Rollbacks: every migration has an upgrade() and downgrade() function, so you can move forward or back to any point in your schema history
    ``` bash
    alembic upgrade head       # apply all migrations
    alembic downgrade -1       # roll back one step
    alembic upgrade abc123     # go to a specific revision
    ```
- Auto-generation: alembic can diff your SQLAlchemy models against the live DB and generate migration scripts automatically
    - `alembic revision --autogenerate -m "add users table"`
- Environment-aware: works cleanly across dev, staging, and production — each environment tracks its own migration state via a alembic_version table.

## getting started
- prerequisite: have a database set up where to create a table 
- `uv add alembic` installation

- bash: `alembic init alembic` => this creates
    - `alembic/`: migration environment directory, migration engine configuration layer, it is part of the application codebase
        - it contains:
            - `env.py`: the runtime configuration that tells Alembic how to connect to your DB and load metadata
            - `script.py.mako`: template for generating migration files
            - `versions/`: your actual migration/database version control history
                - contains files like `1975ea83b712_create_users_table.py`, `ae1027a6acf_add_email_index.py`
                - each file represents: one schema change/one migration revision/a deterministic step in DB history
                - these files contain: `upgrade()` logic, `downgrade()` logic, revision ID, parent revision reference

        - do **NOT** put into `.gitignore`, otherwise schema evolution becomes non-reproducible, CI/CD cannot upgrade DB state, teammates cannot sync schema
    - `alembic.ini`: top-level configuration file
        - contains logging config, script location, runtime settings like database URL (usually left blank here and injected via env vars, to not git commit credentials)
        - required to run `alembic upgrade head`

- write a `Base` class (see `database.py`) that 
    - inherits from `DeclarativeBase` which automatically includes a registry and `MetaData` object attached to `Base.metadata`, which manages all tables mapped to the models
    - is created as an intermediate Base class to establish a shared registry and shared metadata across your entire application
    - every model/mapped class inherits from => Base class automatically registers their table structures into that shared registry and metadata
- write a declarative DB model class that inherits from Base class (see `models/role.py`)

- in `alembic.ini`, set `sqlalchemy.url = `
- in `alembic/env.py` modify:
    1. Extract the model's metadata:
    ``` python
    from app.database import Base
    import app.models

    target_metadata = Base.metadata
    ```
    - in `alembic revision --autogenerate`, alembic uses target_metadata to compare it with current db state with and perform the query (e.f. CREATE, ALTER, DROP etc.) to adapt the current state to match the desired state in `target_metadata`
    - **Important**: alembic does NOT see tables that are NOT imported in the `env.py`
        - `from models import *` is bad practice, keep import deterministic
        - instead: use one central models package initializer: 
            - import all models in `models/__init__.py`
            - in `alembic/env.py`, put simply `import models`
    2. Modify connection section
    ``` python
    from app.config import settings
    config.set_main_option(
        "sqlalchemy.url",
        settings.database_url # type: ignore
    )
    ```
- create first migration: `alembic revision --autogenerate -m "create roles table"`
    - alembic will detect newly defied roles table from metadata
    - => generated file: `alembic/versions/<revision_id>_create_roles_table.py`
- Apply Migration to Cloud SQL: `alembic upgrade head` 

    