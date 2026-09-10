from sqlalchemy import Column, String, Text, DECIMAL, Date, Boolean, Integer, Enum
from sqlalchemy.dialects.postgresql import UUID, ARRAY, JSON
import uuid
from app.db.base_class import Base

class Recycler(Base):
    __tablename__ = "recycler"
    recycler_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String)
    facility_address = Column(Text)
    latitude = Column(DECIMAL)
    longitude = Column(DECIMAL)
    materials_accepted = Column(ARRAY(String))
    auth_number = Column(String)
    auth_status = Column(Enum('Active', 'Expired', 'Suspended', name='auth_status_enum'))
    auth_expiry_date = Column(Date)
    contact_phone = Column(String)
    contact_email = Column(String)
    offered_rates = Column(JSON)
    pickup_available = Column(Boolean)
    service_radius_km = Column(Integer)
    operating_hours = Column(String)
    verified_by_admin = Column(Boolean)
