"""SQLAlchemy engine factory ``create_engine()`` and ORM model base class ``Base``."""

from __future__ import annotations

import logging
from typing import TYPE_CHECKING

from app.exception import UnsupportedAuthSettingsError
from google.cloud.sql.connector import Connector, IPTypes
from sqlalchemy import MetaData, inspect
from sqlalchemy import create_engine as sa_create_engine
from sqlalchemy.orm import DeclarativeBase

if TYPE_CHECKING:
    from sqlalchemy import Engine

    from app.config import DatabaseSettings, IAMAuthSettings, PasswordAuthSettings

logger = logging.getLogger(__name__)

naming_convention = {
    "fk": "fk_%(table_name)s_%(referred_table_name)s_%(column_0_name)s",
    "pk": "pk_%(table_name)s",
    "ix": "ix_%(table_name)s_%(column_0_name)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
}

metadata = MetaData(naming_convention=naming_convention)


class Base(DeclarativeBase):
    """Declarative base class for all SQLAlchemy ORM models.

    All database models should inherit from this class. It provides the
    necessary metadata and registry for SQLAlchemy to track model definitions.
    """

    metadata = metadata

    def __repr__(self):
        """String representation of ORM model instance. Useful for debugging
        and logging.

        Returns:
            str: ORM model representation showing primary key values.
        """
        mapper = inspect(self).mapper
        pk_values = ", ".join(
            f"{col.key}={getattr(self, col.key)!r}"
            for col in mapper.primary_key
            if col.key
        )
        return f"<{self.__class__.__name__}({pk_values})>"


def create_engine(settings: DatabaseSettings) -> Engine:
    """Create a SQLAlchemy engine using the authentication mode implied by *settings*'
    type.
    """

    if isinstance(settings, IAMAuthSettings):
        return _create_iam_engine(settings)
    if isinstance(settings, PasswordAuthSettings):
        return sa_create_engine(settings.database_url)
    raise UnsupportedAuthSettingsError(
        f"Engine cannot be created for type: {type(settings).__name__}"
    )


def _create_iam_engine(settings: IAMAuthSettings) -> Engine:
    """Create an engine that authenticates via Cloud SQL IAM.

    Uses the Cloud SQL Python Connector which handles:
    - Fetching instance metadata via the Cloud SQL Admin API
    - Generating short-lived OAuth2 access tokens
    - Establishing a secure TLS connection to the private IP

    The ``pg8000`` driver is required by the connector for PostgreSQL.
    """

    logger.info(
        "Creating Cloud SQL engine with IAM auth — instance=%s, user=%s",
        settings.instance_connection_name,
        settings.database_iam_user,
    )

    connector = Connector()

    def _getconn():
        return connector.connect(
            settings.instance_connection_name,
            "pg8000",
            user=settings.database_iam_user,
            db=settings.database_name,
            enable_iam_auth=True,
            ip_type=IPTypes.PRIVATE,
        )

    return sa_create_engine(
        "postgresql+pg8000://",
        creator=_getconn,
        pool_pre_ping=True,
    )
