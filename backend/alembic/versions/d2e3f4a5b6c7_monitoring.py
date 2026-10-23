from alembic import op
import sqlalchemy as sa

revision = "d2e3f4a5b6c7"
down_revision = "c1a2b3d4e5f6"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "drift_events",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("asset_id", sa.String(36), sa.ForeignKey("assets.id"), nullable=False),
        sa.Column(
            "scan_result_id", sa.String(36), sa.ForeignKey("scan_results.id"), nullable=False
        ),
        sa.Column("type", sa.String(16), nullable=False),
        sa.Column("component_name", sa.String(255), nullable=False),
        sa.Column("details", sa.Text(), nullable=False),
        sa.Column("detected_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_drift_events_asset_id", "drift_events", ["asset_id"])
    op.create_index("ix_drift_events_scan_result_id", "drift_events", ["scan_result_id"])
    op.create_table(
        "alert_logs",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("project_id", sa.String(36), sa.ForeignKey("projects.id"), nullable=False),
        sa.Column("type", sa.String(64), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("delivery_status", sa.String(32), nullable=False),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_alert_logs_project_id", "alert_logs", ["project_id"])


def downgrade():
    op.drop_table("alert_logs")
    op.drop_table("drift_events")
