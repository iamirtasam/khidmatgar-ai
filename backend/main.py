"""FastAPI app: AI service orchestrator for Pakistan's informal economy."""

from __future__ import annotations

import os
import uuid
from copy import deepcopy
from datetime import datetime
from typing import Any, Dict, List, Optional

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from gemini_agent import GeminiAgent
from models import (
    ChatRequest,
    ConfirmBookingRequest,
    FeedbackRequest,
    StressTestRequest,
)
from sheets_service import SheetsService

load_dotenv()

app = FastAPI(
    title="ServiceOrchestrator API",
    description="AI-powered service orchestrator for Pakistan's informal economy.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------- shared singletons + simple in-memory state ----------

_sheets: Optional[SheetsService] = None
_agent: Optional[GeminiAgent] = None

# session_id -> latest pending booking dict (so /confirm-booking can find it)
_session_pending: Dict[str, Dict[str, Any]] = {}
# user_name -> set of past booking ids (used as a basic returning-user signal)
_user_history: Dict[str, List[str]] = {}


def get_sheets() -> SheetsService:
    global _sheets
    if _sheets is None:
        _sheets = SheetsService()
    return _sheets


def get_agent() -> GeminiAgent:
    global _agent
    if _agent is None:
        _agent = GeminiAgent()
    return _agent


# ---------- helpers ----------

def _is_returning_user(user_name: str) -> bool:
    return bool(user_name) and len(_user_history.get(user_name, [])) > 0


def _record_user_booking(user_name: str, booking_id: str) -> None:
    if not user_name:
        return
    _user_history.setdefault(user_name, []).append(booking_id)


def _safe_get_providers() -> List[Dict[str, Any]]:
    try:
        return get_sheets().get_all_providers()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to load providers: {e}")


def _build_booking_from_agent(
    agent_resp: Dict[str, Any],
    user_name: str,
    session_id: str,
    status: str = "Pending",
    extra_notes: str = "",
) -> Optional[Dict[str, Any]]:
    rec = agent_resp.get("recommended_provider") or {}
    if not rec:
        return None
    intent = agent_resp.get("extracted_intent") or {}
    price = (agent_resp.get("price_quote") or {}).get("total", "")
    provider_id = (
        rec.get("provider_id")
        or rec.get("ProviderID")
        or rec.get("id")
        or ""
    )
    provider_name = rec.get("name") or rec.get("Name") or ""

    notes = f"session:{session_id}"
    if extra_notes:
        notes += f" | {extra_notes}"

    return {
        "BookingID": str(uuid.uuid4()),
        "UserName": user_name,
        "Service": intent.get("service_type", ""),
        "Location": intent.get("location", ""),
        "DateTime": intent.get("preferred_time", ""),
        "ProviderID": provider_id,
        "ProviderName": provider_name,
        "Price": price,
        "Status": status,
        "Notes": notes,
    }


# ---------- endpoints ----------

@app.get("/")
def root():
    return {
        "service": "ServiceOrchestrator API",
        "status": "ok",
        "endpoints": [
            "/chat",
            "/confirm-booking",
            "/feedback",
            "/providers",
            "/booking/{booking_id}",
            "/stress-test/no-provider",
            "/stress-test/cancellation",
        ],
    }


@app.get("/providers")
def list_providers():
    return {"providers": _safe_get_providers()}


@app.get("/booking/{booking_id}")
def get_booking(booking_id: str):
    try:
        booking = get_sheets().get_booking(booking_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Sheets error: {e}")
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking


@app.post("/chat")
def chat(req: ChatRequest):
    providers = _safe_get_providers()
    try:
        agent_resp = get_agent().analyze(
            user_message=req.message,
            providers=providers,
            user_name=req.user_name,
            is_returning_user=_is_returning_user(req.user_name),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Agent error: {e}")

    # Enrich top_providers with full provider data
    provider_lookup = {}
    for p in providers:
        pid = str(p.get("ID", p.get("id", "")))
        pname = str(p.get("Name", p.get("name", "")))
        provider_lookup[pid] = p
        provider_lookup[pname.lower()] = p

    for tp in agent_resp.get("top_providers", []):
        pid = str(tp.get("provider_id", ""))
        pname = str(tp.get("name", "")).lower()
        full = provider_lookup.get(pid) or provider_lookup.get(pname)
        if full:
            tp["rating"] = full.get("Rating", full.get("rating", 0))
            tp["pricePerHour"] = full.get("PricePerHour", full.get("pricePerHour", 0))
            tp["onTimeScore"] = full.get("OnTimeScore", full.get("onTimeScore", 0))
            tp["cancellationRate"] = full.get("CancellationRate", full.get("cancellationRate", ""))
            tp["specialization"] = full.get("Specialization", full.get("specialization", ""))
            tp["area"] = full.get("Area", full.get("area", ""))
            tp["phone"] = full.get("Phone", full.get("phone", ""))
            tp["available"] = full.get("Available", full.get("available", False))

    pending_booking: Optional[Dict[str, Any]] = None
    confidence = float(agent_resp.get("confidence_score") or 0)
    needs_clarif = bool(agent_resp.get("clarification_needed"))

    if confidence >= 70 and not needs_clarif and agent_resp.get("recommended_provider"):
        booking_data = _build_booking_from_agent(
            agent_resp, req.user_name, req.session_id, status="Pending"
        )
        if booking_data:
            try:
                pending_booking = get_sheets().create_booking(booking_data)
                _session_pending[req.session_id] = pending_booking
                agent_resp["booking_action"] = (
                    f"Pending booking {pending_booking['BookingID']} created. "
                    f"Awaiting user confirmation."
                )
            except Exception as e:
                agent_resp["booking_action"] = f"Failed to create pending booking: {e}"

    return {
        "agent": agent_resp,
        "pending_booking": pending_booking,
    }


@app.post("/confirm-booking")
def confirm_booking(req: ConfirmBookingRequest):
    pending = _session_pending.get(req.session_id)
    booking_id: Optional[str] = None

    if pending:
        booking_id = pending["BookingID"]
    else:
        # Fallback: look up in Google Sheets (resilient to server restart)
        sheet_bookings = get_sheets().find_bookings_by_session(req.session_id)
        if not sheet_bookings:
            raise HTTPException(
                status_code=404, detail="No pending booking found for this session."
            )
        booking_id = sheet_bookings[0].get("BookingID")

    new_status = "Confirmed" if req.confirmed else "Cancelled"
    try:
        updated = get_sheets().update_booking_status(booking_id, new_status)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Sheets error: {e}")

    if req.confirmed:
        _record_user_booking(req.user_name, booking_id)
    _session_pending.pop(req.session_id, None)

    return {"booking": updated, "status": new_status}


@app.post("/feedback")
def feedback(req: FeedbackRequest):
    try:
        updated = get_sheets().update_booking_feedback(
            req.booking_id, req.rating, req.comment or ""
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Sheets error: {e}")

    rating = req.rating
    if rating >= 4:
        reputation_note = (
            f"Provider reputation boosted (+{rating - 3} points). "
            "Future ranking will favor this provider."
        )
    elif rating == 3:
        reputation_note = "Provider reputation unchanged. Neutral feedback recorded."
    else:
        reputation_note = (
            f"Provider reputation decreased ({rating - 3} points). "
            "Future ranking will deprioritize this provider."
        )

    return {"booking": updated, "reputation_note": reputation_note}


# ---------- stress tests ----------

@app.post("/stress-test/no-provider")
def stress_test_no_provider(req: StressTestRequest):
    """Simulate all providers being unavailable."""
    providers = _safe_get_providers()
    simulated = deepcopy(providers)
    for p in simulated:
        p["Availability"] = False

    message = req.message or "AC theek karwana hai abhi, urgent hai"
    try:
        agent_resp = get_agent().analyze(
            user_message=message,
            providers=simulated,
            user_name=req.user_name or "",
            is_returning_user=_is_returning_user(req.user_name or ""),
            scenario_note=(
                "STRESS TEST: All providers are temporarily unavailable. "
                "Do NOT recommend any provider. Set recommended_provider to null. "
                "In booking_action, suggest the next reasonable time slot (e.g. "
                "'Tomorrow 10:00 AM') when providers may be free and offer to "
                "notify the user."
            ),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Agent error: {e}")

    agent_resp["recommended_provider"] = None
    if not agent_resp.get("booking_action"):
        agent_resp["booking_action"] = (
            "No providers available right now. Suggested next slot: tomorrow 10:00 AM. "
            "We will notify you when a provider becomes available."
        )
    return {"scenario": "no-provider", "agent": agent_resp}


@app.post("/stress-test/cancellation")
def stress_test_cancellation(req: StressTestRequest):
    """Simulate the originally booked provider cancelling; agent must reassign."""
    providers = _safe_get_providers()
    if not providers:
        raise HTTPException(status_code=400, detail="No providers in sheet.")

    message = req.message or "Plumber chahiye Gulshan mein, kal subah"
    user_name = req.user_name or "TestUser"
    session_id = req.session_id or f"stress-{uuid.uuid4().hex[:8]}"

    # Step 1: initial recommendation
    try:
        first = get_agent().analyze(
            user_message=message,
            providers=providers,
            user_name=user_name,
            is_returning_user=_is_returning_user(user_name),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Agent error (initial): {e}")

    first_rec = first.get("recommended_provider") or {}
    cancelled_id = (
        first_rec.get("provider_id")
        or first_rec.get("ProviderID")
        or first_rec.get("id")
        or ""
    )

    # Step 2: remove cancelled provider and re-ask agent for reassignment
    remaining = [
        p for p in providers
        if str(p.get("ProviderID", p.get("provider_id", ""))) != str(cancelled_id)
    ]

    try:
        second = get_agent().analyze(
            user_message=message,
            providers=remaining,
            user_name=user_name,
            is_returning_user=_is_returning_user(user_name),
            scenario_note=(
                f"STRESS TEST: The originally recommended provider "
                f"(ID={cancelled_id}) just cancelled after booking. "
                "Reassign to the next best available provider from the remaining "
                "list. Mention the reassignment clearly in booking_action and "
                "agent_reasoning_trace."
            ),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Agent error (reassign): {e}")

    return {
        "scenario": "cancellation",
        "session_id": session_id,
        "original_recommendation": first_rec,
        "cancelled_provider_id": cancelled_id,
        "reassigned": second,
    }
