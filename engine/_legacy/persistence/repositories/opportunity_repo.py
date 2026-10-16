
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from ..models.all_models import OpportunityModel


class OpportunityRepo:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_by_id(self, id: str) -> OpportunityModel | None:
        result = await self.session.execute(select(OpportunityModel).where(OpportunityModel.id == id))
        return result.scalars().first()

    async def get_by_canonical_url(self, url: str) -> OpportunityModel | None:
        result = await self.session.execute(select(OpportunityModel).where(OpportunityModel.canonical_url == url))
        return result.scalars().first()

    async def find_by_fingerprint(self, fingerprint: str) -> str | None:
        result = await self.session.execute(select(OpportunityModel.id).where(OpportunityModel.fingerprint == fingerprint))
        row = result.first()
        return str(row[0]) if row else None

    async def find_simhash_candidates(self, simhash: int, hamming_threshold: int = 3) -> list[dict]:
        # Dummy implementation since simhash distance requires custom sqlite function
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
        category: str | None = None,
        country: str | None = None,
        language: str | None = None,
        deadline_before: str | None = None,
        deadline_after: str | None = None,
        amount_min: int | None = None,
        amount_max: int | None = None,
        is_saved: bool | None = None,
        min_score: int | None = None,
        sort_by: str = 'score',
        cursor: str | None = None,
        limit: int = 20,
    ) -> tuple[list[dict], str | None]:
        
        stmt = select(OpportunityModel)
        
        if country:
            stmt = stmt.where(OpportunityModel.country_code == country)
        if language:
            stmt = stmt.where(OpportunityModel.language_code == language)
        if deadline_before:
            stmt = stmt.where(OpportunityModel.deadline_on <= deadline_before)
        if deadline_after:
            stmt = stmt.where(OpportunityModel.deadline_on >= deadline_after)
            
        # Basic pagination based on created_at or id could be implemented, skipping for now
        stmt = stmt.limit(limit)
        
        result = await self.session.execute(stmt)
        opps = result.scalars().all()
        
        items = []
        for opp in opps:
            items.append({
                "id": opp.id,
                "title": opp.title,
                "organization": opp.organization_name,
                "summary": opp.summary,
                "country_code": opp.country_code,
                "deadline": opp.deadline_on,
                "status": opp.verification_status,
                "url": opp.canonical_url
            })
            
        return items, None

    async def get_dashboard_counters(self, user_id: str) -> dict:
        return {"total": 0, "saved": 0, "applied": 0}

    async def get_upcoming_deadlines(self, user_id: str, limit: int) -> list[dict]:
        return []
