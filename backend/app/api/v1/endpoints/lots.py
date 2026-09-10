from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from typing import List
from app.api.deps import get_current_collector, get_db
from app.models.material import Material
from app.models.collector import Collector
from app.schemas.lot import LotCreate, LotResponse
from app.core.cloudinary_config import upload_lot_photo

router = APIRouter()

@router.post("/create", response_model=LotResponse)
def create_lot(
    lot_in: LotCreate,
    db: Session = Depends(get_db),
    current_collector: Collector = Depends(get_current_collector)
):
    db_lot = Material(
        category=lot_in.material_category,
        sub_category=lot_in.sub_category,
        approximate_weight=lot_in.approximate_weight,
        condition=lot_in.condition,
        source_type=lot_in.source_type
    )
    db.add(db_lot)
    db.commit()
    db.refresh(db_lot)
    
    # Set the category field in the response model since it's expected
    lot_response = LotResponse.model_validate(db_lot)
    lot_response.material_category = db_lot.category
    lot_response.lot_id = db_lot.material_id
    
    return lot_response

@router.get("/{collector_id}", response_model=List[LotResponse])
def get_lots(
    collector_id: str,
    db: Session = Depends(get_db),
    current_collector: Collector = Depends(get_current_collector)
):
    # Retrieve active lots. Currently no collector_id in Material model per schema, but in a real app there would be.
    # For now returning all lots.
    lots = db.query(Material).all()
    return lots

@router.post("/{lot_id}/photos")
def upload_photo(
    lot_id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_collector: Collector = Depends(get_current_collector)
):
    lot = db.query(Material).filter(Material.material_id == lot_id).first()
    if not lot:
        raise HTTPException(status_code=404, detail="Lot not found")
        
    try:
        file_bytes = file.file.read()
        image_url = upload_lot_photo(file_bytes, lot_id, 0)
        lot.image_path = image_url
        db.commit()
        return {"image_url": image_url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Image upload failed: {str(e)}")
