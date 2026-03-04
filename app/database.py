from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Declarative base class for all SQLAlchemy ORM models.

    All database models should inherit from this class. It provides the
    necessary metadata and registry for SQLAlchemy to track model definitions.

    Example:
        >>> class User(Base):
        ...     __tablename__ = "users"
        ...     id = Column(Integer, primary_key=True)
    """

    pass
