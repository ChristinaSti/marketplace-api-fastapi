from typing import TYPE_CHECKING

from sqlalchemy import Identity, SmallInteger, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from .user_role import UserRole


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
        Identity(always=True),
        nullable=False,
        primary_key=True,
        doc="Auto-incrementing role identifier",
    )

    name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        doc="Unique role name (e.g., 'seller', 'customer')",
    )

    user_roles: Mapped[list["UserRole"]] = relationship(back_populates="role")

    __table_args__ = (UniqueConstraint("name", name="uk_roles_name"),)
