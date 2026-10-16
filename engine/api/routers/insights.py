"""Dashboard, monitors, notifications, workspaces, exports and privacy (M11, M13, M15, M16, M18)."""

from __future__ import annotations

import asyncio
import json
from typing import Annotated, Any, Literal

from fastapi import APIRouter, File, Response, UploadFile
from pydantic import BaseModel, Field

from api.deps import Active, StateDep
from api.http_utils import attachment
from core.errors import ValidationFailed
from services.dashboard_service import DashboardService
from services.export_service import ExportService
from services.monitor_service import MonitorService, NotificationService
from services.privacy_service import ERASABLE, PrivacyService
from services.tracking_service import TrackingService
from services.workspace_service import WorkspaceService

router = APIRouter(tags=["Insights"])


# ---------------------------------------------------------------- dashboard
@router.get("/dashboard")
def dashboard(active: Active) -> dict[str, Any]:
    return DashboardService(active).summary()


# ----------------------------------------------------------------- monitors
class MonitorIn(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    filters: dict[str, Any]
    schedule_kind: Literal["daily", "weekly", "custom_cron"] = "daily"
    schedule_expr: str = Field(default="08:00", max_length=40)
    min_score: int = Field(default=50, ge=0, le=100)
    source_ids: list[str] = Field(default_factory=list, max_length=100)
    workspace_id: str | None = None


class MonitorPatch(BaseModel):
    name: str | None = Field(default=None, max_length=120)
    filters: dict[str, Any] | None = None
    schedule_kind: Literal["daily", "weekly", "custom_cron"] | None = None
    schedule_expr: str | None = Field(default=None, max_length=40)
    min_score: int | None = Field(default=None, ge=0, le=100)
    enabled: bool | None = None
    source_ids: list[str] | None = None


@router.get("/monitors")
def monitors(active: Active, state: StateDep) -> dict[str, Any]:
    return {"items": MonitorService(active, state).list_items(), "runs_only_while_open": True}


@router.post("/monitors", status_code=201)
def create_monitor(body: MonitorIn, active: Active, state: StateDep) -> dict[str, Any]:
    return MonitorService(active, state).create(body.model_dump())


@router.get("/monitors/history")
def monitor_history(active: Active, state: StateDep) -> dict[str, Any]:
    return {"items": MonitorService(active, state).history()}


@router.get("/monitors/{monitor_id}")
def get_monitor(monitor_id: str, active: Active, state: StateDep) -> dict[str, Any]:
    svc = MonitorService(active, state)
    return svc.get(monitor_id) | {"runs": svc.runs(monitor_id)}


@router.patch("/monitors/{monitor_id}")
def patch_monitor(monitor_id: str, body: MonitorPatch, active: Active, state: StateDep) -> dict[str, Any]:
    return MonitorService(active, state).update(monitor_id, body.model_dump(exclude_unset=True))


@router.delete("/monitors/{monitor_id}", status_code=204)
def delete_monitor(monitor_id: str, active: Active, state: StateDep) -> None:
    MonitorService(active, state).delete(monitor_id)


@router.post("/monitors/{monitor_id}/run", status_code=202)
async def run_monitor(monitor_id: str, active: Active, state: StateDep) -> dict[str, Any]:
    return await MonitorService(active, state).run(monitor_id)


# ------------------------------------------------------------ notifications
class ReadIn(BaseModel):
    ids: list[str] | None = None


class PreferenceIn(BaseModel):
    enabled: bool
    quiet_from: str | None = Field(default=None, pattern=r"^\d{2}:\d{2}$")
    quiet_to: str | None = Field(default=None, pattern=r"^\d{2}:\d{2}$")


class OffsetsIn(BaseModel):
    offsets: list[int] = Field(min_length=1, max_length=8)


@router.get("/notifications")
def notifications(active: Active, state: StateDep, unread: bool = False) -> dict[str, Any]:
    return {"items": NotificationService(active, state).list_items(unread)}


@router.post("/notifications/read", status_code=204)
def mark_read(body: ReadIn, active: Active, state: StateDep) -> None:
    NotificationService(active, state).mark_read(body.ids)


@router.get("/notifications/preferences")
def preferences(active: Active, state: StateDep) -> dict[str, Any]:
    return {"items": NotificationService(active, state).preferences()}


@router.put("/notifications/preferences/{kind}", status_code=204)
def set_preference(kind: str, body: PreferenceIn, active: Active, state: StateDep) -> None:
    NotificationService(active, state).set_preference(kind, body.enabled, body.quiet_from, body.quiet_to)


@router.put("/notifications/reminder-offsets", status_code=204)
def set_offsets(body: OffsetsIn, active: Active, state: StateDep) -> None:
    NotificationService(active, state).set_reminder_offsets(body.offsets)


# --------------------------------------------------------------- workspaces
class WorkspaceIn(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    description: str | None = Field(default=None, max_length=2000)
    template_code: str | None = None
    color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")


class WorkspacePatch(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    description: str | None = Field(default=None, max_length=2000)
    color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")
    archived: bool | None = None


class NoteIn(BaseModel):
    body: str = Field(min_length=1, max_length=10_000)


class CompareIn(BaseModel):
    ids: list[str] = Field(min_length=2, max_length=4)


@router.get("/workspaces/templates")
def templates(active: Active) -> dict[str, Any]:
    return {"items": WorkspaceService(active).templates()}


@router.get("/workspaces")
def workspaces(active: Active, archived: bool = False) -> dict[str, Any]:
    return {"items": WorkspaceService(active).list_items(archived)}


@router.post("/workspaces", status_code=201)
def create_workspace(body: WorkspaceIn, active: Active) -> dict[str, Any]:
    return WorkspaceService(active).create(body.name, body.description, body.template_code, body.color)


@router.get("/workspaces/{ws_id}")
def workspace(ws_id: str, active: Active) -> dict[str, Any]:
    return WorkspaceService(active).detail(ws_id)


@router.patch("/workspaces/{ws_id}")
def patch_workspace(ws_id: str, body: WorkspacePatch, active: Active) -> dict[str, Any]:
    return WorkspaceService(active).update(ws_id, body.model_dump(exclude_unset=True))


@router.delete("/workspaces/{ws_id}", status_code=204)
def delete_workspace(ws_id: str, active: Active) -> None:
    WorkspaceService(active).delete(ws_id)


@router.put("/workspaces/{ws_id}/opportunities/{opp_id}")
def add_ws_opportunity(ws_id: str, opp_id: str, active: Active) -> dict[str, Any]:
    return WorkspaceService(active).add_opportunity(ws_id, opp_id)


@router.delete("/workspaces/{ws_id}/opportunities/{opp_id}")
def remove_ws_opportunity(ws_id: str, opp_id: str, active: Active) -> dict[str, Any]:
    return WorkspaceService(active).remove_opportunity(ws_id, opp_id)


@router.post("/workspaces/{ws_id}/notes", status_code=201)
def add_ws_note(ws_id: str, body: NoteIn, active: Active) -> dict[str, Any]:
    return WorkspaceService(active).add_note(ws_id, body.body)


@router.delete("/workspaces/{ws_id}/notes/{note_id}")
def delete_ws_note(ws_id: str, note_id: str, active: Active) -> dict[str, Any]:
    return WorkspaceService(active).delete_note(ws_id, note_id)


@router.post("/opportunities/compare")
def compare(body: CompareIn, active: Active) -> dict[str, Any]:
    return {"items": WorkspaceService(active).compare(body.ids)}


# ------------------------------------------------------------------ exports
class ExportIn(BaseModel):
    format: Literal["csv", "xlsx", "pdf", "json"]
    scope: Literal["selection", "filtered_results", "workspace", "saved", "applications"]
    ids: list[str] | None = Field(default=None, max_length=2000)
    run_id: str | None = None
    workspace_id: str | None = None
    include_personal_data: bool = False
    language: Literal["fr", "en"] = "fr"


@router.post("/exports")
def export(body: ExportIn, active: Active) -> Response:
    name, mime, data = ExportService(active).export(
        body.format,
        body.scope,
        ids=body.ids,
        run_id=body.run_id,
        workspace_id=body.workspace_id,
        include_personal=body.include_personal_data,
        lang=body.language,
    )
    return Response(content=data, media_type=mime, headers=attachment(name))


@router.post("/exports/personal-data")
def personal_data(active: Active) -> Response:
    name, data = ExportService(active).personal_archive()
    return Response(content=data, media_type="application/zip", headers=attachment(name))


@router.post("/imports/json")
async def import_json(active: Active, file: Annotated[UploadFile, File()]) -> dict[str, int]:
    raw = await file.read(50 * 1024 * 1024 + 1)
    try:
        payload = json.loads(raw)
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        raise ValidationFailed("invalid JSON file", code="import_format_invalid") from exc
    return await asyncio.to_thread(ExportService(active).import_json, payload)


# ------------------------------------------------------------------ privacy
class EraseIn(BaseModel):
    kinds: list[Literal[ERASABLE]] = Field(min_length=1)  # type: ignore[valid-type]
    confirmation: Literal["ERASE"]


class TrackingSettingsIn(BaseModel):
    auto_archive_days: int = Field(ge=0, le=3650)


class NetworkIn(BaseModel):
    proxy_url: str | None = Field(default=None, max_length=300)
    data_saver: bool = False
    max_mb_per_search: int = Field(default=50, ge=5, le=1000)


@router.get("/privacy")
def privacy(active: Active) -> dict[str, Any]:
    return PrivacyService(active).dashboard()


@router.post("/privacy/consents/{consent_id}/revoke")
def revoke(consent_id: str, active: Active) -> dict[str, Any]:
    return PrivacyService(active).revoke_consent(consent_id)


@router.post("/privacy/erase")
def erase(body: EraseIn, active: Active, state: StateDep) -> dict[str, int]:
    result = PrivacyService(active).erase(list(body.kinds))
    if "logs" in body.kinds:
        removed = 0
        for f in state.paths.logs.glob("*.log*"):
            try:
                f.write_text("", encoding="utf-8")
                removed += 1
            except OSError:
                continue
        result["logs"] = removed
    return result


@router.get("/settings/network")
def network(active: Active) -> dict[str, Any]:
    return PrivacyService(active).network()


@router.put("/settings/network")
def set_network(body: NetworkIn, active: Active) -> dict[str, Any]:
    return PrivacyService(active).set_network(body.proxy_url, body.data_saver, body.max_mb_per_search)


@router.get("/settings/tracking")
def tracking_settings(active: Active) -> dict[str, Any]:
    return {"auto_archive_days": TrackingService(active).auto_archive_days()}


@router.put("/settings/tracking")
def set_tracking_settings(body: TrackingSettingsIn, active: Active) -> dict[str, Any]:
    return {"auto_archive_days": TrackingService(active).set_auto_archive_days(body.auto_archive_days)}
