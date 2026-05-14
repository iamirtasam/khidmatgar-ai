from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


# ---------- Request models ----------

class ChatRequest(BaseModel):
    message: str
    user_name: str
    session_id: str
    response_language: Optional[str] = "auto"


class ConfirmBookingRequest(BaseModel):
    session_id: str
    user_name: str
    confirmed: bool


class FeedbackRequest(BaseModel):
    booking_id: str
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = ""


class StressTestRequest(BaseModel):
    message: Optional[str] = None
    user_name: Optional[str] = "TestUser"
    session_id: Optional[str] = "stress-session"


# ---------- Gemini agent response sub-models ----------

class ExtractedIntent(BaseModel):
    service_type: Optional[str] = None
    location: Optional[str] = None
    preferred_time: Optional[str] = None
    urgency: Optional[str] = None
    budget_sensitivity: Optional[str] = None


class TopProvider(BaseModel):
    provider_id: Optional[str] = None
    name: Optional[str] = None
    score: Optional[float] = None
    reasoning: Optional[str] = None


class RankingFactors(BaseModel):
    specialization: Optional[float] = None
    availability: Optional[float] = None
    reliability: Optional[float] = None
    distance: Optional[float] = None
    rating: Optional[float] = None
    price: Optional[float] = None


class PriceQuote(BaseModel):
    base_fee: Optional[float] = None
    distance_adjustment: Optional[float] = None
    urgency_surcharge: Optional[float] = None
    loyalty_discount: Optional[float] = None
    total: Optional[float] = None
    breakdown_explanation: Optional[str] = None


class AgentResponse(BaseModel):
    confidence_score: float = 0
    clarification_needed: bool = False
    clarification_question: Optional[str] = ""
    extracted_intent: ExtractedIntent = ExtractedIntent()
    top_providers: List[TopProvider] = []
    ranking_factors: RankingFactors = RankingFactors()
    recommended_provider: Optional[Dict[str, Any]] = None
    price_quote: PriceQuote = PriceQuote()
    booking_action: Optional[str] = ""
    agent_reasoning_trace: List[str] = []
