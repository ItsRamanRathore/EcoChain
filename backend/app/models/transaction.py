from sqlalchemy import Column, String, DECIMAL, Enum, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSON
import uuid
from app.db.base_class import Base

class Transaction(Base):
    __tablename__ = "transaction"
    transaction_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    lot_id = Column(UUID(as_uuid=True), ForeignKey('material.material_id'))
    collector_id = Column(UUID(as_uuid=True), ForeignKey('collector.collector_id'))
    recycler_id = Column(UUID(as_uuid=True), ForeignKey('recycler.recycler_id'))
    material_category = Column(String)
    quantity_weight = Column(DECIMAL)
    quoted_price = Column(DECIMAL)
    final_price = Column(DECIMAL)
    collection_location = Column(JSON)
    handover_location = Column(JSON)
    collection_datetime = Column(DateTime(timezone=True))
    handover_datetime = Column(DateTime(timezone=True))
    payment_method = Column(Enum('Cash', 'UPI', 'Bank', 'Pending', name='payment_method_enum'))
    payment_status = Column(Enum('Paid', 'Pending', 'Disputed', name='payment_status_enum'))
    transaction_status = Column(Enum('Created', 'Matched', 'Confirmed', 'Completed', 'Cancelled', name='transaction_status_enum'))
