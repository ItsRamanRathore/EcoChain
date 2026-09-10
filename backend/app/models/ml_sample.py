from sqlalchemy import Column, String, DECIMAL, Enum, DateTime
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime, timezone
from app.db.base_class import Base

class MLSample(Base):
    __tablename__ = "ml_sample"
    ml_sample_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    image_path = Column(String)
    material_category = Column(String)
    material_sub_cat = Column(String)
    weight_kg = Column(DECIMAL)
    location_district = Column(String)
    transaction_price = Column(DECIMAL)
    label_source = Column(Enum('Human', 'Model', 'Crowdsourced', name='label_source_enum'))
    label_confidence = Column(DECIMAL)
    split = Column(Enum('Train', 'Validation', 'Test', name='split_enum'))
    created_at = Column(DateTime(timezone=True), default=datetime.now(timezone.utc))
