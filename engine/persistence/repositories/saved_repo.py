from typing import Optional
from datetime import datetime
from sqlalchemy import select, update, delete
from sqlalchemy.ext.asyncio import AsyncSession
from ..models.all_models import SavedOpportunity, ReminderModel

class SavedRepo:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_by_id(self, id: str) -> Optional[SavedOpportunity]:
        result = await self.session.execute(select(SavedOpportunity).where(SavedOpportunity.id == id))
        return result.scalars().first()

    async def get_by_opportunity_and_user(self, opportunity_id: str, user_id: str) -> Optional[SavedOpportunity]:
        result = await self.session.execute(
            select(SavedOpportunity)
            .where(SavedOpportunity.opportunity_id == opportunity_id)
            .where(SavedOpportunity.user_id == user_id)
        )
        return result.scalars().first()

    async def create(self, user_id: str, opportunity_id: str, priority: int, notes: str, personal_deadline: Optional[datetime]) -> str:
        saved = SavedOpportunity(
            user_id=user_id,
            opportunity_id=opportunity_id,
            priority=priority,
            notes=notes,
            personal_deadline=personal_deadline
        )
        self.session.add(saved)
        await self.session.flush()
        return str(saved.id)

    async def update(self, id: str, priority: int, notes: str, personal_deadline: Optional[datetime]) -> None:
        await self.session.execute(
            update(SavedOpportunity)
            .where(SavedOpportunity.id == id)
            .values(priority=priority, notes=notes, personal_deadline=personal_deadline)
        )
        await self.session.flush()

    async def delete(self, id: str) -> None:
        await self.session.execute(delete(SavedOpportunity).where(SavedOpportunity.id == id))
        await self.session.flush()

    async def list_for_user(self, user_id: str, priority_filter: Optional[int], sort_by: str, cursor: Optional[str], limit: int) -> list[dict]:
        return []

    async def create_reminder(self, saved_opportunity_id: str, user_id: str, due_at: datetime, title: str, body: str) -> str:
        reminder = ReminderModel(
            saved_opportunity_id=saved_opportunity_id,
            user_id=user_id,
            due_at=due_at,
            title=title,
            body=body
        )
        self.session.add(reminder)
        await self.session.flush()
        return str(reminder.id)

    async def get_pending_reminders(self, before: datetime) -> list[dict]:
        # dummy implementation
        return []

    async def mark_reminder_sent(self, id: str) -> None:
        await self.session.execute(
            update(ReminderModel)
            .where(ReminderModel.id == id)
            .values(is_sent=True)
        )
        await self.session.flush()
