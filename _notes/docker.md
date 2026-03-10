# docker

## Dockerfile
- is a text file that contains a set of instruction for building a docker container image
- it assembles the application environment step by step: each instruction in the Dockerfile creates a new layer in the image when you run `docker build`

- **Docker container image**: lightweight, standalone, static, read-only executable package that includes everything needed to run a piece of software - the code, runtime (this is the python interpreter for python), libraries, environment variables, configuration files

- **Docker container**: the running instance of the image

## Multi-stage build
- separation of heavy builder image (compilers, curl, build dependencies) and minimal runtime image (Python + app)
- virtual environment is then copied from the builder image to the runtime image
- Benefits: smaller runtime image, faster cold starts, smaller attack surface


## Syntax
- `FROM python:3.14-slim`: 
    - `slim`: removing some system tools and files (e.g. gcc, g++, make (C compilers), apt cache and package list, etc.) from the full Python image that are not necessary for FastAPI app with pure python dependencies
        - => may need installing system dependencies manually
        - => image size ~ 130 MB vs. 900 MB for the full image
    - alternatives:
        - `alpine` smallest size (~ 50 MB), minimal attack surface, uses musl instead of glibc as C standard library (low level bridge between programs and the OS e.g. to read/write files, allocate memory, make network connection, etc.) => since many Python packages (especially ones with C extensions like numpy, pandas) are compiled against glibc, it can cause packages to fail or require compiling from source — making builds slow and painful
- `WORKDIR /code`:  
    - sets the working directory inside the container for any RUN, CMD, ENTRYPOINT, COPY, and ADD instructions that follow it in the Dockerfile,is like doing `cd /code`, all subsequent commands run from this directory
    - it is convention to chose short generic path (here `/code` but also often `/app` which would leads t nested repetition of that name) instead of matching host names (which would be `marketplace-api-fastapi` here)
- `ENV PYTHONUNBUFFERED=1`:
    - forces Python to output logs instantly as they happen, instead of collecting it in buffer and them print them in chunks which may lead to losing the last logs if the container crashes
- `ENV PYTHONDONTWRITEBYTECODE=1`:
    - Normally Python compiles your .py files into .pyc bytecode cache files stored in __pycache__ folders. In a container, these cache files are pointless and just add unnecessary size as the container is rebuilt from scratch each time anyway.
- `RUN apt-get update && apt-get install -y --no-install-recommends build-essential`: 
    - RUN <command> executes any command in  a new layer on top of the current image and commits the result
    - needed when installing python packages that have C extensions  that need to be installed from source
    - build-essential is a meta-package that installs gcc, g++, make, and other compilation tools
    - packages with C-extensions:
        - psycopg2 — the standard PostgreSQL driver (though psycopg2-binary avoids this)
        - cryptography — used under the hood by many auth libraries
        - numpy, scipy, pandas — heavy data/science libraries
    - `--no-install-recommends`: recommended packages can include documentation, localization files, helper utilities, SSL extras, etc. which are often not needed in containers
- `rm -rf /var/lib/apt/lists/*`: 
    - `apt-get update`: downloads package index files (metadata (i.e. package names; versions; dependencies; repository metadata) about available packages) and stores them in `/var/lib/apt/lists/` (typically 10–30 MB of data)
        - they are only needed for installing packages, not for running your app => can be removed for smaller image (but less relevant for builder than for runtime image where it would affect cold start time and deployment speed)
    - need to use `&&` because each RUN creates a new layer => previous layer would still contain the files even though they were removed in the layer after
- `curl -LsSf https://astral.sh/uv/install.sh | sh`:
    - downloads a precompiled binary of uv
    - Pros: official install method by Astral, very fast
    - Cons: `curl | sh` executes remote code immediately which can be a security risk, version pinning by specifying it in the URL, requires curl
    - using `pip install uv` instead?
        - Pros: simplicity, no external script required, transparent dependency resolution with PyPI, easy version pinning for reproducible builds
        - Cons: slightly slower (4-6 s instead of ~ 1s with external script), not as optimized as the the primary distribution channel by Astral
- `COPY pyproject.toml uv.lock* ./`
    - `COPY <src> <dest>`: Copies new files or directories from <src> and adds them to the filesystem of the container at the path <dest>.
    - leveraging Docker’s layer caching to avoid reinstalling dependencies every time the application code changes => can dramatically speed up builds in CI systems
        1. COPY only your dependency manifest
        2. RUN the install command
        3. COPY the rest of your source code
- `RUN uv sync --frozen`: 
    - `--frozen`:  instructs uv to use the existing uv.lock file as-is, preventing it from updating the lockfile, resolving new dependencies, or upgrading packages => reproducible, deterministic builds in production or CI/CD environments
- `RUN addgroup --system app && adduser --system --ingroup app app`: 
    - `--ingroup app`: adds the user to the app group
    - system group/user is a special type of user account meant for running services/daemons, not for human login
        - system user: 
            - no home directory created (for regular user it is)
            - no login (regular users have bash as login shell)
            - lower UID range between 100-999 (reg.: 1000+)
    - security rule: production containers should never run as root (principle of least privilege: only give the process the permissions it needs to run, nothing more)
    - by default everything in docker container runs as root => potential attacker can modify system files, install packages, read sensitive files owned by root, ...
    - the copied files and directories the app user needs should already have read and execute permissions in the "other" bits (for everyone including the app user) where needed
- `COPY alembic/ alembic.ini ./`
    - Single source directory: copies contents into destination (i.e. `COPY alembic/ alembic/` and `COPY alembic/ ./`)
    - Multiple sources: copies each item by name into destination directory
    - `./` trailing slash clarifies that destination is a directory not a file

- `EXPOSE 8080`: documents the intended container port but doesn't publish it (-p in docker run or the equivalent in your orchestrator like Cloud Run / Kubernetes does), is used by some orchestrators/proxies.

- `CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]`
    - exec form (`CMD ["command"]`) -> **PREFERRED!**, shell form (`CMD command`)
        - Background: what happens on container shutdown?
            1. Orchestrator (Docker/K8s/Cloud Run) sends SIGTERM to PID 1 in the container
            2. The process is expected to finish in-flight requests and shut down cleanly/gracefully
            3. After a grace period of several seconds, SIGKILL is sent — instant, non-catchable kill
        - **Exec form**: CMD ["uvicorn", ...] => uvicorn is PID 1 => receives SIGTERM directly
        - **Shell form**: CMD uvicorn ... => /bin/sh is PID 1 => sh receives SIGTERM, may swallow it/not forward it to uvicorn => keeps running until SIGKILL arrives => NO graceful shutdown
        - **Graceful Shutdown**: stops accepting new connections, waits for in-flight requests to complete, closes DB connection pools cleanly, runs any registered shutdown event handlers, exits with code 0
        - **SIGKILL** (no graceful shutdown): dropped requests (e.g. user payment state remains unclear), potentially broken DB connections as not returned to pool, incomplete transactions, lost cleanups (e.g. temp files, metric flush), ...
    - for the choice of uvicorn see `web_server.md`
    - `0.0.0.0`: 
        - means "listen to all network interfaces" -> required for Docker to forward traffic into the container
        - by default, Uvicorn binds to 127.0.0.1 which would be unreachable from outside the container
    - `8080`: Uvicorn listens on this port inside the container. pick whatever you want as port, just make sure your docker run -p, docker-compose.yml, Kubernetes containerPort, or Cloud Run config matches it
    - `app.main:app`: is used to locate the FastAPI application instance, `<module>:<variable>`, it means: 'Import "app" from the Python module "app.main"', `<variable>` can also be a callable (function) that returns the ASGI app bit the `--factory` must be added in that case (Pros of this factory pattern: allows env-specific configuration, easier testing, avoids global state, more flexible initialization)
## dockerignore
- when building a Docker image, the goal is to include only the files that the application needs to
run while keeping the image secure and the size small
- **What to copy in**: source code, dependency manifest (e.g. pyproject.toml), configuration files, ...
- **What to keep out**: local dependencies (e.g. .venv, should be installed inside the container to match the container's OS), Secrets and Credentials (no .env files, SSH keys or API tokens in the image, use env variables or secret management tools instead), temporary files, build artifacts, logs, test results, version control, OS-specific files
- even if in Dockerfile we use the COPY command to explicitly chose what files go into the image, it is good to use a `.dockerignore` file to automatically exclude files
## build and run the container
- in directory with Dockerfile: `docker build -t <image-name>:<tag> .`
    - `.` is the build context, it tells where to look for Dockerfile and other necessary files
    - if tag is not given, it defaults to `latest`
- `docker run -p <host>:<container> <image-name>:<tag>`, e.g. `docker run -p 9000:8080 my-app:1.0`
    - Networking: in Dockerfile, CMD tells Uvicorn to listen on 0.0.0.0:8080 but that port is inside the container's private network. The -p 9000:8080 flag acts as a bridge, telling Docker to take traffic from host machine's port 9000 (e.g. localhost:9000) and send it to the container's port 8080. Without that flag, it is impossible to connect to the app inside the container.









