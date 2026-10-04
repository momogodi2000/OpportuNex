from pydantic import BaseModel
from typing import List, Dict, Any

class OpportunityModel(BaseModel):
    id: str
    
class UserProfile(BaseModel):
    id: str
    
class MatchingWeights(BaseModel):
    skills: float = 0.3
    education: float = 0.15
    experience: float = 0.15
    location: float = 0.15
    languages: float = 0.10
    objectives: float = 0.10
    deadline: float = 0.05

class MatchScore(BaseModel):
    total_score: float
    criteria: Dict[str, float]
    strengths: List[str]
    gaps: List[str]
    conditions_to_verify: List[str]

class MatchScorer:
    def score(self, opportunity: OpportunityModel, profile: UserProfile, weights: MatchingWeights) -> MatchScore:
        score = 85.0
        return MatchScore(
            total_score=score,
            criteria={},
            strengths=["Strong skills match"],
            gaps=["Minor education gap"],
            conditions_to_verify=[]
        )
