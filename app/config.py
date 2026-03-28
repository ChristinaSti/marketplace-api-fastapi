import os
from functools import lru_cache

from pydantic import PostgresDsn, SecretStr, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class DatabaseSettings(BaseSettings):
    """Database settings shared by every authentication mode.
    Values can be passed via the case-insensitive field names as constructor arguments,
    env variables, `.env` file values, field default values and are prioritized in this
    order.
    """

    database_name: str

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )


class PasswordAuthSettings(DatabaseSettings):
    """Password-based authentication settings for local development."""

    database_user: str
    database_password: SecretStr
    database_host: str
    database_port: int = 5432
    database_dialect: str = "postgresql"
    database_driver: str = "psycopg"

    @property
    def database_schema(self) -> str:
        """Generate database schema from dialect and driver."""
        return f"{self.database_dialect}+{self.database_driver}"

    @computed_field
    @property
    def database_url(self) -> str:
        """Generate PostgreSQL DSN from individual components for the psycopg driver.

        Returns:
            str: PostgreSQL connection string in format postgresql+psycopg://user:pass@host:port/db
        """
        return PostgresDsn.build(
            scheme=self.database_schema,
            username=self.database_user,
            password=self.database_password.get_secret_value(),
            host=self.database_host,
            port=self.database_port,
            path=self.database_name,
        ).unicode_string()


class IAMAuthSettings(DatabaseSettings):
    """Cloud SQL IAM authentication settings for production."""

    instance_connection_name: str
    database_iam_user: str


@lru_cache
def get_settings() -> DatabaseSettings:
    """Get or create cached settings instance.

    The settings object is cached using lru_cache decorator to avoid
    redundant environment variable parsing. Creates a new Settings instance
    on first call and returns the cached instance on subsequent calls.

    Returns:
        DatabaseSettings: Cached database settings instance.

    Note:
        The cache persists for the lifetime of the application. To reload
        settings during testing, use get_settings.cache_clear().
    """
    use_iam = os.getenv("DATABASE_USE_IAM_AUTH", "false").lower() in (
        "true",
        "1",
        "yes",
    )
    if use_iam:
        return IAMAuthSettings()  # type: ignore[call-arg]
    return PasswordAuthSettings()  # type: ignore[call-arg]


# Global settings instance for application use
settings = get_settings()
