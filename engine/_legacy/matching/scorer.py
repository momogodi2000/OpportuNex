from pydantic import BaseModel
from typing import Any

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
    criteria: dict[str, float]
    strengths: list[str]
    gaps: list[str]
    conditions_to_verify: list[str]

class MatchScorer:
    def score(self, opportunity: Any, profile: Any, weights: MatchingWeights = MatchingWeights()) -> MatchScore:
        # Generic heuristic logic without assuming strict pydantic structures 
        total_score = 0.0
        criteria_scores = {}
        strengths = []
        gaps = []
        conditions_to_verify = []

        # Convert to dicts for flexible access if they are objects
        opp_dict = opportunity.model_dump() if hasattr(opportunity, "model_dump") else (opportunity.__dict__ if hasattr(opportunity, "__dict__") else opportunity)
        prof_dict = profile.model_dump() if hasattr(profile, "model_dump") else (profile.__dict__ if hasattr(profile, "__dict__") else profile)

        if type(opp_dict) is not dict: opp_dict = {}
        if type(prof_dict) is not dict: prof_dict = {}

        # 1. Location (15%)
        opp_location = str(opp_dict.get('location') or opp_dict.get('country') or '').lower()
        prof_location = str(prof_dict.get('location') or prof_dict.get('residence_country') or '').lower()
        if opp_location and prof_location and (prof_location in opp_location or opp_location in prof_location):
            criteria_scores['location'] = weights.location * 100
            strengths.append(f"Localisation correspondante ({prof_location.title()})")
        else:
            criteria_scores['location'] = 0.0
            if opp_location:
                conditions_to_verify.append(f"Vérifier l'éligibilité pour: {opp_location.title()}")

        # 2. Languages (10%)
        # Just stubbing some logic
        criteria_scores['languages'] = weights.languages * 100
        
        # 3. Skills overlap (30%)
        opp_desc = str(opp_dict.get('summary') or opp_dict.get('title') or '').lower()
        prof_skills = prof_dict.get('skills') or []
        if type(prof_skills) is str: prof_skills = [prof_skills]
        
        matched_skills = []
        for s in prof_skills:
            if isinstance(s, str) and s.lower() in opp_desc:
                matched_skills.append(s)

        if len(prof_skills) > 0 and len(matched_skills) > 0:
            ratio = len(matched_skills) / max(len(prof_skills), 3) # penalize if too few skills
            score_skills = min(1.0, ratio) * weights.skills * 100
            criteria_scores['skills'] = score_skills
            if score_skills > (weights.skills * 50):
                strengths.append(f"Compétences correspondantes: {', '.join(matched_skills)}")
            else:
                gaps.append(f"Certaines compétences requises peuvent manquer.")
        else:
            criteria_scores['skills'] = weights.skills * 50 # Default middle score
            conditions_to_verify.append("Analyser plus en détail les compétences requises")

        # 4. Education & Experience (30% combined)
        criteria_scores['education'] = weights.education * 80
        criteria_scores['experience'] = weights.experience * 80
        
        # 5. Objectives & Deadline (15% combined)
        criteria_scores['objectives'] = weights.objectives * 70
        criteria_scores['deadline'] = weights.deadline * 100 # assuming active
        
        total_score = sum(criteria_scores.values())

        return MatchScore(
            total_score=round(total_score, 1),
            criteria={k: round(v, 1) for k, v in criteria_scores.items()},
            strengths=strengths if strengths else ["Profil potentiellement compatible"],
            gaps=gaps,
            conditions_to_verify=conditions_to_verify
        )
