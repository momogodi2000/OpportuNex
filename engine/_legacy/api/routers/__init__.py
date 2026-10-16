from .ai import router as ai_router
from .application import router as application_router
from .auth import router as auth_router
from .cv_import import router as cv_import_router
from .dashboard import router as dashboard_router
from .export import router as export_router
from .maintenance import router as maintenance_router
from .monitor import router as monitor_router
from .opportunity import router as opportunity_router
from .organization import router as organization_router
from .privacy import router as privacy_router
from .profile import router as profile_router
from .ref import router as ref_router
from .saved import router as saved_router
from .search import router as search_router
from .source import router as source_router
from .sync import router as sync_router
from .system import router as system_router
from .workspace import router as workspace_router

__all__ = [name for name in dir() if name.endswith('_router')]
