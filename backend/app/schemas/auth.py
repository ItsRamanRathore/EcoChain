from pydantic import BaseModel
from typing import Optional

class LoginRequest(BaseModel):
    google_token: Optional[str] = None
    mock_role: Optional[str] = None  # "collector" or "recycler"

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    user_id: str
    display_name: str
