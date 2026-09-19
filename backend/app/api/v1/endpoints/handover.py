from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timezone
import uuid
import json
from app.api.deps import get_current_collector, get_db
from app.models.traceability import Traceability
from app.models.material import Material
from app.models.recycler import Recycler
from app.models.collector import Collector
from app.models.transaction import Transaction
from app.schemas.handover import HandoverGenerate, HandoverResponse, HandoverConfirm, HandoverVerifyResponse

from typing import Optional

router = APIRouter()

@router.post("/{lot_id}/generate")
def generate_handover(
    lot_id: str,
    payload: HandoverGenerate,
    db: Session = Depends(get_db),
    current_collector = Depends(get_current_collector)
):
    lot = db.query(Material).filter(Material.material_id == lot_id).first()
    if not lot:
        # Auto-create Material for offline sync flow
        lot = Material(
            material_id=lot_id,
            category=payload.material_category,
            approximate_weight=payload.actual_weight,
        )
        db.add(lot)
        db.flush()
        
    try:
        # Single transaction — both records created or neither
        transaction = Transaction(
            transaction_id=uuid.uuid4(),
            lot_id=lot_id,
            collector_id=current_collector.collector_id,
            recycler_id=payload.recycler_id,
            quantity_weight=payload.actual_weight,
            final_price=payload.final_price,
            quoted_price=payload.final_price,
            collection_location={"lat": payload.handover_gps["lat"], 
                                  "lng": payload.handover_gps["lng"]},
            transaction_status="Created",
            payment_status="Pending",
            material_category=lot.category,
        )
        db.add(transaction)
        db.flush()  # get transaction_id without committing

        ref_number = f"HO-{datetime.now().year}-MH-{uuid.uuid4().hex[:8].upper()}"
        
        gps_str = json.dumps(payload.handover_gps)
        
        traceability = Traceability(
            trace_id=uuid.uuid4(),
            lot_id=lot_id,
            weight_at_collection=payload.actual_weight,
            collection_gps=gps_str,
            collection_timestamp=datetime.now(timezone.utc),
            handover_ref_number=ref_number,
            qr_code_data=json.dumps({
                "ref": ref_number,
                "lot_id": str(lot_id),
                "collector_id": str(current_collector.collector_id)
            }),
        )
        db.add(traceability)
        db.commit()  # both committed together

        # Join for full response
        recycler = db.query(Recycler).filter(Recycler.recycler_id == payload.recycler_id).first()

        return {
            "trace_id": str(traceability.trace_id),
            "lot_id": str(lot_id),
            "ref_number": ref_number,
            "qr_code_data": traceability.qr_code_data,
            "material_category": transaction.material_category or lot.category,
            "weight_at_collection": payload.actual_weight,
            "recycler_name": recycler.name if recycler else "",
            "recycler_auth_number": recycler.auth_number if recycler else "",
            "collector_display_name": current_collector.display_name,
            "status": "Pending",
            "collection_timestamp": traceability.collection_timestamp.isoformat(),
        }
    except Exception as e:
        db.rollback()  # ← critical — if either insert fails, neither persists
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{lot_id}/confirm")
def confirm_handover(
    lot_id: str,
    confirm_in: HandoverConfirm,
    db: Session = Depends(get_db),
    # Note: normally recycler auth needed here
):
    trace_record = db.query(Traceability).filter(Traceability.lot_id == lot_id).first()
    if not trace_record:
        raise HTTPException(status_code=404, detail="Handover record not found")

    now = datetime.now(timezone.utc)

    # Update traceability record
    trace_record.recycler_confirmation = True
    trace_record.recycler_confirm_time = now
    trace_record.handover_timestamp = now
    trace_record.handover_gps = confirm_in.handover_gps
    trace_record.weight_at_handover = confirm_in.actual_weight

    # Also complete the associated transaction so the recycler dashboard
    # moves it from "Pending" to "Recent Transactions".
    transaction = db.query(Transaction).filter(Transaction.lot_id == lot_id).first()
    if transaction:
        transaction.transaction_status = 'Completed'
        transaction.handover_datetime = now
        transaction.quantity_weight = confirm_in.actual_weight
        transaction.final_price = confirm_in.final_price
        transaction.handover_location = confirm_in.handover_gps

        # Increment the collector's lifetime stats so their profile page stays current.
        collector = db.query(Collector).filter(
            Collector.collector_id == transaction.collector_id
        ).first()
        if collector:
            collector.total_transactions = (collector.total_transactions or 0) + 1
            collector.total_earnings = (
                float(collector.total_earnings or 0) + float(confirm_in.final_price or 0)
            )

    db.commit()
    return {"message": "Handover confirmed successfully"}


@router.get("/{ref_number}/verify", response_model=HandoverVerifyResponse)
def verify_handover(
    ref_number: str,
    db: Session = Depends(get_db)
):
    trace_record = db.query(Traceability).filter(Traceability.handover_ref_number == ref_number).first()
    if not trace_record:
        raise HTTPException(status_code=404, detail="Handover record not found")
        
    lot = db.query(Material).filter(Material.material_id == trace_record.lot_id).first()
    transaction = db.query(Transaction).filter(Transaction.lot_id == trace_record.lot_id).first()
    
    recycler_name = "Unknown"
    recycler_auth_number = "Unknown"
    collector_display_name = "Unknown"
    status = "Pending"
    
    if transaction:
        recycler = db.query(Recycler).filter(Recycler.recycler_id == transaction.recycler_id).first()
        collector = db.query(Collector).filter(Collector.collector_id == transaction.collector_id).first()
        if recycler:
            recycler_name = recycler.name
            recycler_auth_number = recycler.auth_number
        if collector:
            collector_display_name = collector.display_name
        status = transaction.transaction_status

    return {
        "ref_number": ref_number,
        "material_category": lot.category if lot else "Unknown",
        "weight_at_collection": trace_record.weight_at_collection,
        "weight_at_handover": trace_record.weight_at_handover,
        "recycler_name": recycler_name, 
        "recycler_auth_number": recycler_auth_number,
        "collector_display_name": collector_display_name,
        "status": status,
        "collection_timestamp": trace_record.collection_timestamp,
        "handover_timestamp": trace_record.handover_timestamp,
        "handover_gps": trace_record.handover_gps
    }
