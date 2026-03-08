# Model: User

## `Mapped`:
- newly introduced in SQLAlchemy 2
- primary goal: provide correct static typing for ORM attributes (needed by Python type checker) while keeping the ORM mapping explicit and unambiguous

## `UUID(as_uuid=True)`
- `default=uuid.uuid7` defines what version of UUID is generated
- `as_uuid`: controls how the value is represented in Python, not in PostgreSQL where it is saved as 16-byte binary, SQLAlchemy handles the conversion between the two
    - True: `UUID('6f7f9e2c-2a9a-4f52-8e7c-8c2d4f2a9f33')` (preferred: better python typing, easier comparisons, ...)
    - False: `"6f7f9e2c-2a9a-4f52-8e7c-8c2d4f2a9f33"` (as 36-character hexadecimal string)

## `DateTime(timezone=True)`:
- PostgreSQL stores timestamp normalized to UTC (coordinated universal time), especially recommended for distributed systems

## `__table_args__`:
- typical uses: 
    - Table constraints
        - UniqueConstraint: multi/single-column constraints (or inline `unique=True` but then, deterministic custom constraint naming for easier migrations and debugging is not possible)
        - PrimaryKeyConstraint ...(or inline `primary_key=True`....)
        - ForeignKeyConstraint
        - CheckConstraint
    - Index definitions

## `Index("ux_users_email_lower", func.lower(email), unique=True),`:
- many major email providers treat email addresses as case-insensitive => uniqueness should be case-insensitive for data integrity
- Why alternatives do not seem practical:
    - UniqueConstraint cannot use expressions => `UNIQUE(lower(email))` does not work
    - for `citext`, an extension is needed, not in standard PostgreSQL18
    - for nondeterministic collation, some managed services have specific restrictions on custom collations (ICU provider must be supported)

## `onupdate=func.now()`:
- Postgres does not support natively the `ON UPDATE` functionality that MySQL does
- Works entirely in Python/SQLAlchemy, ORM dependent (as opposed to database-enforced and client-independent)
- Alternatively in stricter production setups you might use a trigger => testing and migrations are more complicated

## `class UserStatus(StrEnum)`:
- for python < 3.11: `class UserStatus(str, enum.Enum)`
- without str inheritance, `UserStatus.ACTIVE == "ACTIVE"` is `False`, the string value must be accessed vit `UserStatus.ACTIVE.value`
- with str inheritance, the enum behaves like a string subtype: `isinstance(UserStatus.ACTIVE, str)` is `True`
- **Benefits**: easier comparison; json serialization can automatically handle strings but not enums; works with frameworks and databases expecting strings

## `Enum(UserStatus, name="user_status", native_enum=True),`
- When `native_enum=True`, SQLAlchemy creates a PostgreSQL enum type in the database. PostgreSQL requires that type to have a name
    - `CREATE TYPE user_status AS ENUM ('ACTIVE', 'SUSPENDED', 'PENDING', 'DISABLED', 'DELETED');`
    - Then your table column uses that type: `status user_status NOT NULL`
    - it needs a name because PostgreSQL enums are schema-level types, not just column definitions. They can be reused across tables
    - Pros: strong schema typing (type user-status instead of generic text), reusable across tables, clearer DB schema
    - Cons: Enum migrations are harder (e.g. removing or renaming values can require rebuilding the type), tight coupling to PostgreSQL (enum type may not exist in other DBs)
    - => use when Enum values rarely change and no DB change is intended
- If you set `Enum(UserStatus, native_enum=False)`, SQLAlchemy stores the value as a VARCHAR with a CHECK constraint.
    ``` sql
    status VARCHAR(8) NOT NULL
    CHECK (status IN ('ACTIVE','SUSPENDED','PENDING','DISABLED','DELETED'))
    ```
    - => the enum exists only in the column constraint, not as a database type.
    - Pros: easier migrations that native enum (but see cons), cross-DB compatibility
    - Cons: 
        - schema less expressive (VARCHAR instead of domain type)
        - Enum(native_enum=False) often creates "hidden" constraints that Alembic may struggle to track or rename correctly (https://github.com/sqlalchemy/alembic/issues/363)
    - => use when: frequent enum changes expected, multi-DB support needed
- Alternative: “application-level enum”
    - idea: Keep the enum strict in Python, but store it as a plain string in the database:
        `status: Mapped[UserStatus] = mapped_column(String(20), nullable=False)`
    - => avoids PostgreSQL enum migration issues while still giving you strong typing in your application
    - Optional: if you want DB safety too, add a check constraint, automatically derive values from Enum
        ``` python
        def enum_check(enum_cls, column_name):
            values = ", ".join(f"'{e.value}'" for e in enum_cls)
            return CheckConstraint(f"{column_name} IN ({values})")
        # ...
        __table_args__ = (
            enum_check(UserStatus, "status"),
        )
        ```
        - -> `(f"{"'ACTIVE', 'DELETED'"}")` -> `('ACTIVE', 'DELETED')`(evaluate the expression inside the {} of an f-string)
- Best alternative to avoid all migration issues: create a separate user_statuses DB lookup table
    - Pros:
        - No schema migrations for value changes (add, rename, deactivate)
        - possibility to store additional metadata (e.g. `allowed_login`)
    - Cons: unnecessary complexity for static Enums, queries need extra join, extra index, harder to map user status entity cleanly to python enum
