from sqlalchemy import Column, String, Integer, DECIMAL, Date, Enum
from sqlalchemy.dialects.postgresql import UUID
import uuid
from app.db.base_class import Base

class Collector(Base):
    __tablename__ = "collector"
    collector_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    preferred_language = Column(Enum('Hindi', 'Marathi', 'English', name='language_enum'))
    operating_district = Column(String)
    operating_state = Column(String)
    registration_date = Column(Date)
    total_transactions = Column(Integer)
    total_earnings = Column(DECIMAL)
    display_name = Column(String)
    phone_hash = Column(String)
