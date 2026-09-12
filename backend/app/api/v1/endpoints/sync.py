from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from app.api.deps import get_current_collector, get_db
from app.models.price import Price
from app.models.recycler import Recycler
from app.schemas.sync import SyncPushRequest, SyncPushResponse, SyncPullResponse

router = APIRouter()

@router.post("/push", response_model=SyncPushResponse)
def sync_push(
    push_in: SyncPushRequest,
    db: Session = Depends(get_db),
    current_collector = Depends(get_current_collector)
):
    from app.models.material import Material
    import uuid
    results = []
    for lot_data in push_in.lots:
        try:
            lot_dict = lot_data.model_dump(exclude={'local_id'})
            material = Material(
                material_id=uuid.uuid4(),
                collector_id=current_collector.collector_id,
                **lot_dict
            )
            db.add(material)
            db.commit()
            db.refresh(material)
            results.append({
                'local_id': lot_data.local_id,
                'server_id': str(material.material_id),
                'success': True,
            })
        except Exception as e:
            db.rollback()
            results.append({
                'local_id': lot_data.local_id,
                'success': False,
                'error': str(e),
            })
    return {'results': results}

@router.get("/pull", response_model=SyncPullResponse)
def sync_pull(
    since: str,
    db: Session = Depends(get_db),
    current_collector = Depends(get_current_collector)
):
    # `since` is ISO format timestamp
    try:
        since_time = datetime.fromisoformat(since)
    except ValueError:
        since_time = datetime.now(timezone.utc)
        
    # Mocking sync query. Should filter by updated_at if implemented on model.
    prices = db.query(Price).all()
    recyclers = db.query(Recycler).filter(
        Recycler.auth_status == 'Active',
        Recycler.approval_status == 'approved'
    ).all()
    
    return {
        "prices": prices,
        "recyclers": recyclers,
        "timestamp": datetime.now(timezone.utc)
    }
