"""scan results, components and vulnerabilities

Revision ID: c1a2b3d4e5f6
Revises: 9e1e22ab1535
Create Date: 2026-10-16 10:30:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "c1a2b3d4e5f6"
down_revision: Union[str, Sequence[str], None] = "9e1e22ab1535"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        "scan_results",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("asset_id", sa.String(length=36), nullable=False),
        sa.Column("component_count", sa.Integer(), nullable=False),
        sa.Column("critical_vulnerability_count", sa.Integer(), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("finished_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.ForeignKeyConstraint(["asset_id"], ["assets.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    with op.batch_alter_table("scan_results", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_scan_results_asset_id"), ["asset_id"], unique=False)

    op.create_table(
        "components",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("scan_result_id", sa.String(length=36), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("version", sa.String(length=255), nullable=False),
        sa.Column("ecosystem", sa.String(length=64), nullable=False),
        sa.Column("purl", sa.String(length=512), nullable=False),
        sa.Column("license", sa.String(length=255), nullable=False),
        sa.ForeignKeyConstraint(["scan_result_id"], ["scan_results.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    with op.batch_alter_table("components", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_components_scan_result_id"), ["scan_result_id"], unique=False
        )

    op.create_table(
        "vulnerabilities",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("component_id", sa.String(length=36), nullable=False),
        sa.Column("cve_id", sa.String(length=255), nullable=False),
        sa.Column("severity", sa.String(length=16), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.ForeignKeyConstraint(["component_id"], ["components.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("component_id", "cve_id", name="uq_vulnerability_component_cve"),
    )
    with op.batch_alter_table("vulnerabilities", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_vulnerabilities_component_id"), ["component_id"], unique=False
        )


def downgrade() -> None:
    """Downgrade schema."""
    with op.batch_alter_table("vulnerabilities", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_vulnerabilities_component_id"))

    op.drop_table("vulnerabilities")
    with op.batch_alter_table("components", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_components_scan_result_id"))

    op.drop_table("components")
    with op.batch_alter_table("scan_results", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_scan_results_asset_id"))

    op.drop_table("scan_results")
