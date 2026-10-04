from typing import Any
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from api.dependencies import get_current_user
from domain.entities.entities import User
from persistence.database import get_db_session
from persistence.repositories.workspace_repo import WorkspaceRepo

router = APIRouter(prefix="/workspaces", tags=["workspaces"])

class WorkspaceCreate(BaseModel):
    name: str
    template: str | None = None

class WorkspaceUpdate(BaseModel):
    name: str | None = None
    status: str | None = None

class WorkspaceResponse(BaseModel):
    id: str
    name: str
    status: str
    template: str | None

@router.get("", response_model=list[WorkspaceResponse])
async def list_workspaces(db: AsyncSession = Depends(get_db_session), current_user: User = Depends(get_current_user)):
    repo = WorkspaceRepo(db)
    items = await repo.list_for_user(str(current_user.id))
    return [WorkspaceResponse(id=str(item.id), name=item.name, status=item.status, template="") for item in items]

@router.post("", response_model=WorkspaceResponse)
async def create_workspace(workspace: WorkspaceCreate, db: AsyncSession = Depends(get_db_session), current_user: User = Depends(get_current_user)):
    repo = WorkspaceRepo(db)
    item = await repo.create(str(current_user.id), workspace.name)
    return WorkspaceResponse(id=str(item.id), name=item.name, status=item.status, template="")

@router.get("/{workspace_id}", response_model=dict[str, Any])
async def get_workspace(workspace_id: str):
    return {"id": workspace_id, "name": "Workspace", "status": "active", "search_history": []}

@router.put("/{workspace_id}", response_model=WorkspaceResponse)
async def update_workspace(workspace_id: str, update: WorkspaceUpdate):
    return WorkspaceResponse(id=workspace_id, name=update.name or "Updated", status=update.status or "active", template=None)

@router.delete("/{workspace_id}")
async def delete_workspace(workspace_id: str):
    return {"status": "deleted"}

@router.get("/{workspace_id}/queries", response_model=list[dict[str, Any]])
async def list_workspace_queries(workspace_id: str):
    return []

@router.get("/{workspace_id}/saved", response_model=list[dict[str, Any]])
async def list_workspace_saved_opportunities(workspace_id: str):
    return []
