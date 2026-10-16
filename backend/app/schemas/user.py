from datetime import datetime

from app.schemas.base import PascalModel


class UserOut(PascalModel):
    id: str
    email: str
    created_at: datetime
