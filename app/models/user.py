import uuid
from enum import StrEnum
from typing import TYPE_CHECKING

from sqlalchemy import UUID, CheckConstraint, DateTime, Index, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from .order import Order
    from .user_role import UserRole


class UserStatus(StrEnum):
    ACTIVE = "ACTIVE"
    SUSPENDED = "SUSPENDED"
    PENDING = "PENDING"
    DISABLED = "DISABLED"
    DELETED = "DELETED"


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid7, nullable=False
    )

    name: Mapped[str] = mapped_column(String(255), nullable=False)

    email: Mapped[str] = mapped_column(String(255), nullable=False)

    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    deleted_at: Mapped[DateTime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    status: Mapped[UserStatus] = mapped_column(
        String(20), server_default=UserStatus.ACTIVE, nullable=False
    )

    __table_args__ = (
        Index("ux_users_email_lower", func.lower(email), unique=True),
        CheckConstraint(
            # Dynamically pull values from the Enum to avoid duplication
            f"status IN ({', '.join([f"'{s.value}'" for s in UserStatus])})",
            name="users_status_check",
        ),
    )

    user_roles: Mapped[list["UserRole"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )

    orders: Mapped[list["Order"]] = relationship(back_populates="customer")
