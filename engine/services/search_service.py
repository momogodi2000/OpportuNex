import structlog
import asyncio
from typing import Any, Dict

logger = structlog.get_logger(__name__)

class SearchRunResult:
    def __init__(self, job_id: str, items_found: int, items_new: int):
        self.job_id = job_id
        self.items_found = items_found
        self.items_new = items_new

class SearchService:
    @staticmethod
    async def run_search(filters: Dict[str, Any], user_id: str, job_id: str) -> SearchRunResult:
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
        sources = ["source_a", "source_b"] # dummy
        
        items_found = 0
        items_new = 0

        # 3. For each source (max 8 concurrent)
        semaphore = asyncio.Semaphore(8)

        async def process_source(source):
            nonlocal items_found, items_new
            async with semaphore:
                logger.info("Processing source", source=source)
                # a. Check min_crawl_interval_minutes
                # b. Call reader
                # c. Deduplicator.find_duplicate()
                # d/e. Create/update record
                # f. Emit SOURCE_SCAN_PROGRESS WebSocket event
                items_found += 10
                items_new += 5

        await asyncio.gather(*(process_source(s) for s in sources))

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
        # TODO: Update background_jobs table
