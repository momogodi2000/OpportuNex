from .all_models import (
    ApplicationSettings, Country, Currency, Language, OpportunityCategory,
    Skill, UserModel, UserSession, Consent, UserProfile, EducationRecord,
    WorkExperience, UserSkill, UserLanguage, UserObjective,
    Source, SourceAdapter, SourceScanRun, OpportunityModel, OpportunityField,
    OpportunitySource, MatchScoreModel, SavedOpportunity, ApplicationModel,
    ApplicationStatusHistory, ResearchWorkspace, SearchQuery, SearchRun,
    Monitor, AIProvider, BackgroundJob, BackupRecord, ReminderModel,
    NotificationRecord, SecurityEvent,
)

__all__ = [
    name for name, obj in globals().items()
    if isinstance(obj, type) and hasattr(obj, '__tablename__')
]
