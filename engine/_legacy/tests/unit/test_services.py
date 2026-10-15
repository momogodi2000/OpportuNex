import pytest
from fastapi.testclient import TestClient

from api.app import create_app

app = create_app('test_token')
from services.auth_service import AuthService

client = TestClient(app)

@pytest.mark.asyncio
async def test_auth_service():
    import uuid

    from persistence.database import get_session_factory
    from persistence.repositories.user_repo import UserRepo
    random_email = f"test_{uuid.uuid4().hex[:8]}@example.com"
    SessionLocal = get_session_factory()
    async with SessionLocal() as db:
        user_repo = UserRepo(db)
        auth = AuthService(user_repo)
        user, recovery_phrase, token = await auth.register("Test User", random_email, "Password!12345", "Password!12345")
        assert user is not None
        
        # Test login
        logged_in_user_id, session_token = await auth.login(random_email, "Password!12345")
        assert logged_in_user_id == user

def test_search_service_basic():
    # Since search_service might scrape, we could test a basic search.
    pass
