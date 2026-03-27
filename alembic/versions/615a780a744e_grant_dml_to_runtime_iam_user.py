"""Grant runtime IAM user DML access to all existing and future tables and sequences. 

Revision ID: 615a780a744e
Revises: af7136ab3d9c
Create Date: 2026-04-05 15:12:24.218067

"""

import os
from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = '615a780a744e'
down_revision: Union[str, Sequence[str], None] = 'af7136ab3d9c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _get_runtime_user() -> str:
    """Return the PostgreSQL IAM username for the runtime service account."""
    user = os.environ.get("DATABASE_IAM_RUNTIME_USER") # set by the CD pipeline
    if not user:
        raise RuntimeError(
            "DATABASE_IAM_RUNTIME_USER is not set.  "
            "The CD pipeline must pass the runtime SA's PostgreSQL username "
            "(Terraform output: db_iam_runtime_user)."
        )
    return user.replace('"', '""')


def upgrade() -> None:
    """Upgrade schema."""
    runtime_user = _get_runtime_user()

    op.execute(
        f'GRANT SELECT, INSERT, UPDATE, DELETE '
        f'ON ALL TABLES IN SCHEMA public '
        f'TO "{runtime_user}"'
    )

    op.execute(
        f'GRANT USAGE, SELECT '
        f'ON ALL SEQUENCES IN SCHEMA public '
        f'TO "{runtime_user}"'
    )

    op.execute(
        f'ALTER DEFAULT PRIVILEGES IN SCHEMA public '
        f'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES '
        f'TO "{runtime_user}"'
    )
    op.execute(
        f'ALTER DEFAULT PRIVILEGES IN SCHEMA public '
        f'GRANT USAGE, SELECT ON SEQUENCES '
        f'TO "{runtime_user}"'
    )


def downgrade() -> None:
    """Downgrade schema."""
    runtime_user = _get_runtime_user()

    op.execute(
        f'ALTER DEFAULT PRIVILEGES IN SCHEMA public '
        f'REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES '
        f'FROM "{runtime_user}"'
    )
    op.execute(
        f'ALTER DEFAULT PRIVILEGES IN SCHEMA public '
        f'REVOKE USAGE, SELECT ON SEQUENCES '
        f'FROM "{runtime_user}"'
    )
    op.execute(
        f'REVOKE SELECT, INSERT, UPDATE, DELETE '
        f'ON ALL TABLES IN SCHEMA public '
        f'FROM "{runtime_user}"'
    )
    op.execute(
        f'REVOKE USAGE, SELECT '
        f'ON ALL SEQUENCES IN SCHEMA public '
        f'FROM "{runtime_user}"'
    )
