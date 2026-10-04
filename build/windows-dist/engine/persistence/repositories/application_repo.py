from typing import Optional
from sqlalchemy import select, update, delete
from sqlalchemy.ext.asyncio import AsyncSession
from ..models.all_models import ApplicationModel, ApplicationStatusHistory

class ApplicationRepo:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_by_id(self, id: str) -> Optional[ApplicationModel]:
        result = await self.session.execute(select(ApplicationModel).where(ApplicationModel.id == id))
        return result.scalars().first()

    async def create(self, saved_opportunity_id: str, user_id: str) -> str:
        app = ApplicationModel(saved_opportunity_id=saved_opportunity_id, user_id=user_id, status='draft')
        self.session.add(app)
        await self.session.flush()
        return str(app.id)

    async def update_status(self, id: str, new_status: str, old_status: str, note: Optional[str]) -> None:
        import datetime
        # Insert status history
        history = ApplicationStatusHistory(
            application_id=id,
            old_status=old_status,
            new_status=new_status,
            note=note
        )
        self.session.add(history)
        
        # Update application
        await self.session.execute(
            update(ApplicationModel)
            .where(ApplicationModel.id == id)
            .values(status=new_status, updated_at=datetime.datetime.utcnow())
        )
        await self.session.flush()

    async def get_kanban_board(self, user_id: str) -> dict[str, list[dict]]:
        return {"draft": [], "submitted": [], "under_review": [], "accepted": [], "rejected": []}

    async def get_calendar_events(self, user_id: str, from_date: str, to_date: str) -> list[dict]:
        return []

    async def list_for_user(self, user_id: str, status: Optional[str], cursor: Optional[str], limit: int) -> tuple[list, Optional[str]]:
        return [], None
