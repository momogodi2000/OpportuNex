from sqlalchemy import select, insert, update, delete
from sqlalchemy.ext.asyncio import AsyncSession
from ..models.all_models import ResearchWorkspace

class WorkspaceRepo:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def list_for_user(self, user_id: str):
        stmt = select(ResearchWorkspace).where(ResearchWorkspace.user_id == user_id)
        result = await self.session.execute(stmt)
        return list(result.scalars().all())

    async def create(self, user_id: str, name: str):
        ws = ResearchWorkspace(user_id=user_id, name=name, status="active")
        self.session.add(ws)
        await self.session.flush()
        return ws
