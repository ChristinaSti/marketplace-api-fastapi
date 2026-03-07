from sqlalchemy import Identity, SmallInteger, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Role(Base):
    """User role for authorization and access control.

    Attributes:
        id: Auto-incrementing primary key (SmallInteger, 0-32767 roles max).
        name: Unique name identifier for the role (e.g., 'seller' who can list
        products, 'customer' who can place orders).
    """

    __tablename__ = "roles"

    id: Mapped[int] = mapped_column(
        SmallInteger,
        Identity(always=True),  # auto-incrementing, always=True prevents manual inserts
        nullable=False,  # also implied by primary_key=True
        primary_key=True,
        doc="Auto-incrementing role identifier",
    )

    name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        doc="Unique role name (e.g., 'seller', 'customer')",
    )

    __table_args__ = (UniqueConstraint("name", name="uk_roles_name"),)
