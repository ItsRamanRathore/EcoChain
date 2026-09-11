from sqlalchemy import Column, String
from sqlalchemy.dialects.postgresql import UUID
import uuid
from app.db.base_class import Base

class Admin(Base):
    __tablename__ = "admin"
    admin_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    display_name = Column(String, nullable=False, default="System Admin")
