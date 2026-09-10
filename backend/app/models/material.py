from sqlalchemy import Column, String, Text, DECIMAL, Enum, DateTime
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime, timezone
from app.db.base_class import Base

class Material(Base):
    __tablename__ = "material"
    material_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    category = Column(Enum('CRT', 'LCD', 'PCB', 'Cable', 'Battery', 'Motor', 'Plastic', 'Mixed', name='material_category_enum'))
    sub_category = Column(String)
    description = Column(Text)
    image_path = Column(String)
    approximate_weight = Column(DECIMAL)
    condition = Column(Enum('Good', 'Damaged', 'Mixed', 'Unknown', name='condition_enum'))
    source_type = Column(Enum('Household', 'Commercial', 'Industrial', 'Unknown', name='source_type_enum'))
    estimated_value = Column(DECIMAL)
    created_at = Column(DateTime(timezone=True), default=datetime.now(timezone.utc))
