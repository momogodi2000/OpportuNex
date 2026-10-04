import structlog
from typing import Dict, Any

logger = structlog.get_logger(__name__)

class AIGateway:
    @staticmethod
    async def interpret_query(query: str, profile_summary: Dict[str, Any]) -> Dict[str, Any]:
        logger.info("AIGateway interpreting query", query=query)
        # In a real scenario, this calls an LLM API.
        # Here we mock it slightly smarter.
        keywords = []
        category = None
        country = None
        
        query_lower = query.lower()
        if 'grant' in query_lower or 'subvention' in query_lower:
            category = 'grant'
        if 'award' in query_lower or 'prix' in query_lower:
            category = 'award'
        if 'scholarship' in query_lower or 'bourse' in query_lower:
            category = 'scholarship'
            
        if 'france' in query_lower:
            country = 'FR'
        if 'canada' in query_lower:
            country = 'CA'
            
        words = query_lower.split()
        for w in words:
            if len(w) > 4 and w not in ['grant', 'subvention', 'award', 'prix', 'scholarship', 'bourse', 'france', 'canada']:
                keywords.append(w)
                
        return {
            "keywords": keywords,
            "filters": {
                "category": category,
                "country": country
            },
            "confidence": 0.85
        }
