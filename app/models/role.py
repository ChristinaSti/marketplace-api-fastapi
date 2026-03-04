from sqlalchemy import Column, Identity, SmallInteger, String, UniqueConstraint

from app.database import Base


class Role(Base):
    """User role for authorization and access control.

    Attributes:
        id: Auto-incrementing primary key (SmallInteger, 0-32767 roles max).
        name: Unique name identifier for the role (e.g., 'seller' who can list
        products, 'customer' who can place orders).
    """

    __tablename__ = "roles"

    id = Column(
        SmallInteger,
        Identity(always=True),
        # auto-incrementing, always=True prevents manual inserts
        # nullable=False is not needed as it's implied by primary_key=True
        primary_key=True,
        doc="Auto-incrementing role identifier",
    )
    name = Column(
        String(100),
        nullable=False,
        doc="Unique role name (e.g., 'seller', 'customer')",
    )

    __table_args__ = (UniqueConstraint("name", name="uk_roles_name"),)

    def __repr__(self) -> str:
        """String representation of Role instance. Useful for debugging and logging.

        Returns:
            str: Role representation showing id and name.
        """
        return f"<Role(id={self.id}, name='{self.name}')>"
