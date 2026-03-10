# -------- base stage --------
FROM python:3.14-slim AS base

WORKDIR /code

ENV PYTHONUNBUFFERED=1 \
	PYTHONDONTWRITEBYTECODE=1

# -------- 1. Builder stage --------
FROM base AS builder

RUN apt-get update && apt-get install -y --no-install-recommends curl \
	&& rm -rf /var/lib/apt/lists/* \
	&& curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

COPY pyproject.toml uv.lock* ./
RUN uv sync --frozen --no-dev

# -------- 2. Runtime stage --------
FROM base AS runtime

# run as non-root for security
RUN addgroup --system app && adduser --system --ingroup app app

COPY --from=builder /code/.venv /code/.venv
ENV PATH="/code/.venv/bin:$PATH"

COPY app/ app/
# for running migrations in CI
COPY alembic/ alembic.ini ./

USER app

EXPOSE 8080

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]