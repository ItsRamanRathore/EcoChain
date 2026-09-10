from sqlalchemy import Column, String, DECIMAL, Date, Enum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
import uuid
from app.db.base_class import Base

class Price(Base):
    __tablename__ = "price"
    price_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    material_category = Column(String)
    material_sub_cat = Column(String)
    location_district = Column(String)
    location_state = Column(String)
    date_recorded = Column(Date)
    buying_price = Column(DECIMAL)
    selling_price = Column(DECIMAL)
    unit = Column(Enum('kg', 'piece', 'lot', name='unit_enum'))
    recycler_id = Column(UUID(as_uuid=True), ForeignKey('recycler.recycler_id'))
    market_price_low = Column(DECIMAL)
    market_price_high = Column(DECIMAL)
    source = Column(Enum('Platform', 'Manual', 'Scraped', name='source_enum'))
