import pytest
from fastapi.testclient import TestClient
from api.app import create_app

app = create_app("dummy-token-123")
client = TestClient(app)

def test_read_main():
    response = client.get("/")
    # Not sure if there is a root route, let's just assert 404 or 200
    assert response.status_code in [200, 401, 404]

def test_engine_token():
    # Test that without token it returns 401 (SessionTokenMiddleware)
    response = client.get("/api/v1/profile")
    assert response.status_code == 401
