import cloudinary
import cloudinary.uploader
from app.core.config import settings

cloudinary.config(
    cloud_name=settings.CLOUDINARY_CLOUD_NAME,
    api_key=settings.CLOUDINARY_API_KEY,
    api_secret=settings.CLOUDINARY_API_SECRET,
    secure=True
)

def upload_lot_photo(file_bytes: bytes, lot_id: str, photo_index: int) -> str:
    result = cloudinary.uploader.upload(
        file_bytes,
        folder=f"ecochain/lots/{lot_id}",
        public_id=f"photo_{photo_index}",
        resource_type="image"
    )
    return result.get("secure_url")
