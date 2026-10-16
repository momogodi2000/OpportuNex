"""Shared FastAPI dependencies."""

from __future__ import annotations

from typing import Annotated

from fastapi import Depends, Header, Request

from services.state import ActiveProfile, EngineState


def get_state(request: Request) -> EngineState:
    state: EngineState = request.app.state.engine
    return state


StateDep = Annotated[EngineState, Depends(get_state)]


def current_profile(state: StateDep, authorization: Annotated[str | None, Header()] = None) -> ActiveProfile:
    bearer = None
    if authorization and authorization.lower().startswith("bearer "):
        bearer = authorization[7:].strip()
    return state.require(bearer)


Active = Annotated[ActiveProfile, Depends(current_profile)]
