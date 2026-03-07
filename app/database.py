from sqlalchemy import MetaData, inspect
from sqlalchemy.orm import DeclarativeBase

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

    Example:
        >>> class User(Base):
        ...     __tablename__ = "users"
        ...     id = Column(Integer, primary_key=True)
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
