from typing import TYPE_CHECKING

from sqlalchemy import Identity, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from .product import Product


class ProductCategory(Base):
    __tablename__ = "product_categories"

    id: Mapped[int] = mapped_column(
        Integer, Identity(always=True), nullable=False, primary_key=True
    )

    name: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)

    products: Mapped[list["Product"]] = relationship(back_populates="category")
