"""add_auth_approval_fields

Revision ID: 7895128cfdbb
Revises: a4ef29741ffc
Create Date: 2026-09-11 00:38:39.352628

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7895128cfdbb'
down_revision: Union[str, None] = 'a4ef29741ffc'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create approval_status enum type first (required for PostgreSQL)
    approval_status_enum = sa.Enum('pending', 'approved', 'rejected', name='approval_status_enum')
    approval_status_enum.create(op.get_bind(), checkfirst=True)

    # Admin table
    op.create_table('admin',
        sa.Column('admin_id', sa.UUID(), nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('password_hash', sa.String(), nullable=False),
        sa.Column('display_name', sa.String(), nullable=False),
        sa.PrimaryKeyConstraint('admin_id')
    )
    op.create_index(op.f('ix_admin_email'), 'admin', ['email'], unique=True)

    # Collector new columns
    op.add_column('collector', sa.Column('email', sa.String(), nullable=True))
    op.add_column('collector', sa.Column('pin_hash', sa.String(), nullable=True))
    op.add_column('collector', sa.Column('latitude', sa.DECIMAL(), nullable=True))
    op.add_column('collector', sa.Column('longitude', sa.DECIMAL(), nullable=True))

    # Recycler new columns
    op.add_column('recycler', sa.Column('email', sa.String(), nullable=True))
    op.add_column('recycler', sa.Column('password_hash', sa.String(), nullable=True))
    # Use server_default='approved' so existing seed rows get a valid value
    op.add_column('recycler', sa.Column(
        'approval_status',
        sa.Enum('pending', 'approved', 'rejected', name='approval_status_enum'),
        nullable=False,
        server_default='approved'
    ))
    op.add_column('recycler', sa.Column('rejection_reason', sa.String(), nullable=True))
    op.add_column('recycler', sa.Column('shop_image_url', sa.String(), nullable=True))
    op.add_column('recycler', sa.Column('shop_latitude', sa.DECIMAL(), nullable=True))
    op.add_column('recycler', sa.Column('shop_longitude', sa.DECIMAL(), nullable=True))
    op.create_unique_constraint('uq_recycler_email', 'recycler', ['email'])


def downgrade() -> None:
    op.drop_constraint('uq_recycler_email', 'recycler', type_='unique')
    op.drop_column('recycler', 'shop_longitude')
    op.drop_column('recycler', 'shop_latitude')
    op.drop_column('recycler', 'shop_image_url')
    op.drop_column('recycler', 'rejection_reason')
    op.drop_column('recycler', 'approval_status')
    op.drop_column('recycler', 'password_hash')
    op.drop_column('recycler', 'email')
    op.drop_column('collector', 'longitude')
    op.drop_column('collector', 'latitude')
    op.drop_column('collector', 'pin_hash')
    op.drop_column('collector', 'email')
    op.drop_index(op.f('ix_admin_email'), table_name='admin')
    op.drop_table('admin')
    sa.Enum(name='approval_status_enum').drop(op.get_bind(), checkfirst=True)
