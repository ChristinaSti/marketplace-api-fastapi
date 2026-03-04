from functools import lru_cache

from pydantic import SecretStr, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings managed through environment variables or .env file."""

    database_user: str
    database_password: SecretStr
    database_host: str
    database_port: int = 5432
    database_name: str

    @computed_field
    @property
    def database_url(self) -> str:
        """Generate PostgreSQL connection DSN from individual components.

        Returns:
            str: PostgreSQL connection string in format postgresql+psycopg://user:pass@host:port/db
        """
        return (
            f"postgresql+psycopg://{self.database_user}:"
            f"{self.database_password.get_secret_value()}@"
            f"{self.database_host}:{self.database_port}/{self.database_name}"
        )

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )


@lru_cache
def get_settings() -> Settings:
    """Get or create cached settings instance.

    The settings object is cached using lru_cache decorator to avoid
    redundant environment variable parsing. Creates a new Settings instance
    on first call and returns the cached instance on subsequent calls.

    Returns:
        Settings: Cached application settings instance.

    Note:
        The cache persists for the lifetime of the application. To reload
        settings during testing, use get_settings.cache_clear().
    """
    return Settings()  # type: ignore


# Global settings instance for application use
settings = get_settings()
