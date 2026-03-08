# Model: UserRole

## `if TYPE_CHECKING`:
``` python
    from .user import User
    from .role import Role
```
- typing-only import pattern used to avoid circular import problems while still providing static type checking 
- the block below `if TYPE_CHECKING` is ignored at runtime, but visible to type checkers (mypy, pyright, pylance, etc.)
- this is especially needed here in ORM models, because they often reference each other
- type annotations like `Mapped["User"]` contain a string as a forward reference instead of `Mapped[User]` because due to circular imports, the class might not yet be defined when Python parses the file
- `from __future__ import annotations` makes all annotations lazy strings automatically meaning type annotations are internally stored as strings, e.g. `"Mapped[User]"`, instead of evaluated immediately
- further reduces circular import issues at runtime

## `primary_key=True`:
- unlike PostgreSQL, composite primary key can be defined in the column definitions, not only in __table_args__ as a table-level constraint
- the index of the composite key is ordered by the column that occurs first in the definition (in `UserRole` class this is `user_id`)
    - => if efficient filtering by the second key is also wanted (i.e. because there is frequent WHERE-filtering, ORDER BY and/or JOINs), an index for that key must be created explicitly (in `UserRole` class: `role_id: Mapped[int] = mapped_column(..., index=True)

## constraint naming
- generally, custom naming constraints are useful for debugging (clear names in error messages), for migration safety (predictable naming helps)
- PostgreSQL already has a quiet clear default, e.g. `{table}_{column}_fkey`, but we might prefer also having the `referred_table_name` in it
- in Alembic, I can configure automatic naming conventions like this:
``` python
from sqlalchemy import MetaData

naming_convention = {
    "fk": "fk_%(table_name)s_%(referred_table_name)s_%(column_0_name)s",
    "pk": "pk_%(table_name)s",
    "ix": "ix_%(table_name)s_%(column_0_name)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
}

metadata = MetaData(naming_convention=naming_convention)

class Base(DeclarativeBase):
    metadata = metadata
```
## `user: Mapped["User"] = relationship(back_populates="user_roles")`
## `user_roles: Mapped[list["UserRole"]] = relationship(back_populates="role")`
- bidirectional ORM relationship definition in SQLAlchemy
- `back_populates` references the attribute name on the other model

## `cascade="all, delete-orphan"`
| Cascade Option       | Behavior                                        | When to Use                                                                        |
| -------------------- | ----------------------------------------------- | ---------------------------------------------------------------------------------- |
| `save-update`        | Updates child when parent is updated            | Default minimal cascade                                                            |
| `merge`              | Propagates merge operations                     | Rare, mostly for session merge                                                     |
| `delete`             | Deletes children when parent is deleted         | Use if children should disappear with parent, but not when removed from collection |
| `delete-orphan`      | Deletes children removed from collection        | Use when children **cannot exist independently**                                   |
| `all`                | Includes most operations except `delete-orphan` | General-purpose                                                                    |
| `all, delete-orphan` | All + orphan removal                            | Standard for tightly-coupled association objects                                   |

## `def __repr__(self):`
- it is useful for easier debugging, readable logs, better output in read-eval-print-loop (REPL)/Jupyter
- Options to not implement it separately for every model class:
    - Dataclass mapping:
        ``` python 
        from sqlalchemy.orm import MappedAsDataclass
        # inheritance for every ORM model class separately:
        class User(MappedAsDataclass, Base):
            ...
        # OR all mapped models automatically become dataclasses:
        class Base(DeclarativeBase):
            ...
        ```
        - => these methods are implemented automaticalls: `__init__()`, `__repr__()`, `__eq__()`
        - Cons: Dataclasses introduce rules that affect SQLAlchemy models
            - require field ordering: fields without defaults before fields with defaults
            - relationships need to be excluded from constructor with `init=False`
            - ...
    - universal __repr__()` implementation in Base class
        - should not rely on every class having to have an id attribute (e.g. may not be the case in bridge tables with composite primary keys made up of foreign keys)
        ``` python
        def __repr__(self):  
            mapper = inspect(self).mapper  
            pk_values = ", ".join(  
                f"{col.key}={getattr(self, col.key)!r}"  
                for col in mapper.primary_key  
            )  
            return f"<{self.__class__.__name__}({pk_values})>"
        ```
        - `inspect(obj)`: introspection for ORM objects, gives access to metadata such as mapped columns, relationships, primary keys, table information, returns the instance state
        - `.mapper` attribute provides the ORM mapper that describes how the class maps to the database
        - `mapper.primary_key`: list of Column objects representing the primary key
        -  generator expression inside of join(...) is similar to a list comprehension but avoids creating an intermediate list
        - `getattr(object, attribute_name)` is equivalent to `self.user_id` but dynamic, so this retrieves the actual value stored on the instance
        - `f"{value!r}"` means: use `use repr(value)` instead of `str(value)`
        ``` 
        name = "Alice"
        f"{name}"   -> Alice
        f"{name!r}" -> 'Alice'
        ```
        - repr is safer for debugging because strings show quotes and objects show detailed representations
        - => final format: `<UserRole(user_id=1, role_id=2)`
