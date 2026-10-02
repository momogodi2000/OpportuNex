from typing import Optional
from sqlalchemy import select, update, delete
from sqlalchemy.ext.asyncio import AsyncSession
from ..models.all_models import OpportunityModel

class OpportunityRepo:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_by_id(self, id: str) -> Optional[OpportunityModel]:
        result = await self.session.execute(select(OpportunityModel).where(OpportunityModel.id == id))
        return result.scalars().first()

    async def get_by_canonical_url(self, url: str) -> Optional[OpportunityModel]:
        result = await self.session.execute(select(OpportunityModel).where(OpportunityModel.canonical_url == url))
        return result.scalars().first()

    async def find_by_fingerprint(self, fingerprint: str) -> Optional[str]:
        result = await self.session.execute(select(OpportunityModel.id).where(OpportunityModel.fingerprint == fingerprint))
        row = result.first()
        return str(row[0]) if row else None

    async def find_simhash_candidates(self, simhash: int, hamming_threshold: int = 3) -> list[dict]:
        # TODO: Implement actual simhash calculation depending on dialect
        return []

    async def create(self, data: dict) -> str:
        opp = OpportunityModel(**data)
        self.session.add(opp)
        await self.session.flush()
        return str(opp.id)

    async def update(self, id: str, data: dict) -> bool:
        result = await self.session.execute(
            update(OpportunityModel)
            .where(OpportunityModel.id == id)
            .values(**data)
        )
        await self.session.flush()
        return result.rowcount > 0

    async def list_for_user(
        self,
        user_id: str,
        category: Optional[str] = None,
        country: Optional[str] = None,
        language: Optional[str] = None,
        deadline_before: Optional[str] = None,
        deadline_after: Optional[str] = None,
        amount_min: Optional[int] = None,
        amount_max: Optional[int] = None,
        is_saved: Optional[bool] = None,
        min_score: Optional[int] = None,
        sort_by: str = 'score',
        cursor: Optional[str] = None,
        limit: int = 20,
    ) -> tuple[list[dict], Optional[str]]:
        # TODO: Implement full filtering and pagination
        return [], None

    async def get_dashboard_counters(self, user_id: str) -> dict:
        return {"total": 0, "saved": 0, "applied": 0}

    async def get_upcoming_deadlines(self, user_id: str, limit: int) -> list[dict]:
        return []
