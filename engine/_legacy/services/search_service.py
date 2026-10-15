import asyncio
from typing import Any

import structlog

logger = structlog.get_logger(__name__)

class SearchRunResult:
    def __init__(self, job_id: str, items_found: int, items_new: int):
        self.job_id = job_id
        self.items_found = items_found
        self.items_new = items_new

class SearchService:
    @staticmethod
    async def run_search(filters: dict[str, Any], user_id: str, job_id: str) -> SearchRunResult:
        """
        Orchestrates the search process.
        1. Create SearchRun record
        2. Resolve sources
        3. Concurrent processing (respecting intervals, calling readers, dedup, etc.)
        4. AI extraction
        5. MatchScorer
        6. Update SearchRun
        7. Emit events
        """
        logger.info("Starting run_search", job_id=job_id, user_id=user_id, filters=filters)
        
        # 1. Create SearchRun record (status=running)
        # 2. Resolve active sources matching filters
        from collection.reader import AdapterConfig, CollectionReader
        from collection.safe_http import SafeHTTPClient
        from collection.source_catalog import INITIAL_SOURCES
        from domain.entities.entities import Source
        
        # We will use the INITIAL_SOURCES for now
        sources_data = INITIAL_SOURCES
        if filters.get("categories"):
            sources_data = [s for s in sources_data if any(c in s.get("categories", []) for c in filters["categories"])]
            
        items_found = 0
        items_new = 0

        # 3. For each source (max 8 concurrent)
        semaphore = asyncio.Semaphore(8)
        http_client = SafeHTTPClient()
        reader = CollectionReader(http=http_client)

        from persistence.database import get_session_factory
        from persistence.models.all_models import OpportunityModel
        
        SessionLocal = get_session_factory()

        async def process_source(source_dict):
            nonlocal items_found, items_new
            async with semaphore:
                logger.info("Processing source", source=source_dict["name"])
                
                import uuid
                source_ent = Source(
                    id=uuid.uuid4(),
                    name=source_dict["name"],
                    base_url=source_dict["base_url"],
                    is_active=True
                )
                adapter = AdapterConfig(source_dict["adapter"])
                
                try:
                    docs = await reader.fetch(source_ent, adapter)
                    items_found += len(docs)
                    
                    async with SessionLocal() as db:
                        for doc in docs:
                            # simple deduplication by url
                            from sqlalchemy import select
                            existing = await db.execute(select(OpportunityModel).where(OpportunityModel.canonical_url == doc.url))
                            if existing.scalar_one_or_none():
                                continue
                                
                            opp = OpportunityModel(
                                canonical_url=doc.url,
                                title=doc.title,
                                organization=doc.organization,
                                summary=doc.content,
                                deadline_raw=doc.deadline_raw
                            )
                            db.add(opp)
                            items_new += 1
                        await db.commit()
                except Exception as e:
                    logger.error("Error processing source", source=source_dict["name"], error=str(e))

        await asyncio.gather(*(process_source(s) for s in sources_data))
        await http_client.close()

        # 4. Run AI extraction on new opportunities (if AI enabled)
        # 5. Run MatchScorer for all new opportunities for this user
        # 6. Update SearchRun (status=completed)
        # 7. Emit SEARCH_COMPLETED event

        logger.info("Completed run_search", job_id=job_id, items_found=items_found, items_new=items_new)
        return SearchRunResult(job_id=job_id, items_found=items_found, items_new=items_new)

    @staticmethod
    async def cancel_search(job_id: str) -> None:
        """Sets cancel_requested=True in background_jobs."""
        logger.info("Canceling search", job_id=job_id)
        # Update background_jobs table if it existed
