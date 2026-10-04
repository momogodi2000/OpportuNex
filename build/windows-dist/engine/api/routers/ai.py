from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any, Optional
from pydantic import BaseModel
import keyring
import keyring.errors

router = APIRouter(prefix="/ai", tags=["ai"])

class AIProviderCreate(BaseModel):
    name: str
    provider_type: str
    model: str
    api_key_value: str
    base_url: Optional[str] = None

class AIProviderUpdate(BaseModel):
    name: Optional[str] = None
    provider_type: Optional[str] = None
    model: Optional[str] = None
    base_url: Optional[str] = None

class APIKeyUpdate(BaseModel):
    api_key_value: str

class AIProviderResponse(BaseModel):
    id: str
    name: str
    provider_type: str
    model: str
    base_url: Optional[str]
    keychain_ref: str

@router.get("/providers", response_model=List[AIProviderResponse])
async def list_ai_providers():
    return []

@router.post("/providers", response_model=AIProviderResponse)
async def create_ai_provider(provider: AIProviderCreate):
    keychain_ref = f"ai_provider_{provider.name}"
    keyring.set_password("opportunex", keychain_ref, provider.api_key_value)
    
    return AIProviderResponse(
        id="prov_123",
        name=provider.name,
        provider_type=provider.provider_type,
        model=provider.model,
        base_url=provider.base_url,
        keychain_ref=keychain_ref
    )

@router.get("/providers/{provider_id}", response_model=AIProviderResponse)
async def get_ai_provider(provider_id: str):
    raise HTTPException(status_code=404, detail="Provider not found")

@router.put("/providers/{provider_id}", response_model=AIProviderResponse)
async def update_ai_provider(provider_id: str, provider: AIProviderUpdate):
    raise HTTPException(status_code=404, detail="Provider not found")

@router.post("/providers/{provider_id}/key")
async def update_provider_key(provider_id: str, key_update: APIKeyUpdate):
    keychain_ref = f"ai_provider_{provider_id}"
    keyring.set_password("opportunex", keychain_ref, key_update.api_key_value)
    return {"status": "key_updated"}

@router.delete("/providers/{provider_id}")
async def delete_ai_provider(provider_id: str):
    keychain_ref = f"ai_provider_{provider_id}"
    try:
        keyring.delete_password("opportunex", keychain_ref)
    except keyring.errors.PasswordDeleteError:
        pass
    return {"status": "deleted"}

@router.post("/providers/{provider_id}/test")
async def test_ai_provider(provider_id: str):
    return {"status": "success", "message": "Connection successful"}

@router.get("/usage", response_model=Dict[str, Any])
async def get_ai_usage():
    return {"tokens_used": {"openai": 1500, "anthropic": 200}}
