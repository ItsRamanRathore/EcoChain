from sqlalchemy import Column, String, DECIMAL, DateTime, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, ARRAY
import uuid
from app.db.base_class import Base

class Traceability(Base):
    __tablename__ = "traceability"
    trace_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    lot_id = Column(UUID(as_uuid=True), ForeignKey('material.material_id'))
    photograph_paths = Column(ARRAY(String))
    weight_at_collection = Column(DECIMAL)
    weight_at_handover = Column(DECIMAL)
    collection_gps = Column(String)
    handover_gps = Column(String)
    collection_timestamp = Column(DateTime(timezone=True))
    handover_timestamp = Column(DateTime(timezone=True))
    handover_ref_number = Column(String, unique=True)
    recycler_confirmation = Column(Boolean)
    recycler_confirm_time = Column(DateTime(timezone=True))
    qr_code_data = Column(String)
    subsequent_status = Column(String)
