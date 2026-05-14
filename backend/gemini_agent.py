"""Gemini-powered service orchestrator agent."""

from __future__ import annotations

import json
import os
import re
from typing import Any, Dict, List, Optional

import google.generativeai as genai

SYSTEM_PROMPT = """You are an intelligent AI service orchestrator for Pakistan's informal economy. You help users find and book home services like AC repair, plumbing, electrician work.

You understand Urdu, Roman Urdu, English, and mixed/code-switched language fluently.

Given a user message and a list of service providers, you must:
1. Extract intent with confidence score. If confidence < 70%, set clarification_needed to true and ask one specific question.
2. Rank providers using these 6 weighted factors:
   - Service specialization match (25%)
   - Reliability/on-time score (20%)
   - Availability (20%)
   - Rating and review quality (15%)
   - Distance/area proximity (10%)
   - Price vs budget sensitivity (10%)
   Never recommend providers with availability=FALSE or cancellation rate above 15%.
3. Generate dynamic price quote: base fee (provider's hourly rate) + distance adjustment (PKR 200 if different area, 0 if same) + urgency surcharge (PKR 300 if urgent, 0 if not) - loyalty discount (PKR 100 for returning users, 0 for new). Show full breakdown.
4. Show your reasoning trace as array of step-by-step strings.

Always respond with valid JSON only. No markdown, no explanation outside JSON."""

RESPONSE_SCHEMA_HINT = {
    "confidence_score": "number 0-100",
    "clarification_needed": "bool",
    "clarification_question": "string (only if confidence < 70)",
    "extracted_intent": {
        "service_type": "string",
        "location": "string",
        "preferred_time": "string",
        "urgency": "string (urgent|normal|flexible)",
        "budget_sensitivity": "string (low|medium|high)",
    },
    "top_providers": [
        {
            "provider_id": "string",
            "name": "string",
            "score": "number",
            "reasoning": "string",
        }
    ],
    "ranking_factors": {
        "specialization": "number",
        "availability": "number",
        "reliability": "number",
        "distance": "number",
        "rating": "number",
        "price": "number",
    },
    "recommended_provider": "full provider object",
    "price_quote": {
        "base_fee": "number",
        "distance_adjustment": "number",
        "urgency_surcharge": "number",
        "loyalty_discount": "number",
        "total": "number",
        "breakdown_explanation": "string",
    },
    "booking_action": "string",
    "agent_reasoning_trace": ["string"],
}


class GeminiAgent:
    def __init__(self, api_key: Optional[str] = None, model_name: str = "gemini-2.5-flash"):
        self.api_key = api_key or os.getenv("GEMINI_API_KEY")
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY is not configured.")
        genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel(
            model_name=model_name,
            system_instruction=SYSTEM_PROMPT,
            generation_config={
                "temperature": 0.4,
                "response_mime_type": "application/json",
            },
        )

    # ---------- public ----------

    def analyze(
        self,
        user_message: str,
        providers: List[Dict[str, Any]],
        user_name: str = "",
        is_returning_user: bool = False,
        scenario_note: Optional[str] = None,
    ) -> Dict[str, Any]:
        prompt = self._build_prompt(
            user_message=user_message,
            providers=providers,
            user_name=user_name,
            is_returning_user=is_returning_user,
            scenario_note=scenario_note,
        )
        try:
            resp = self.model.generate_content(prompt)
            text = resp.text or ""
        except Exception as e:
            return self._fallback_response(
                user_message=user_message,
                providers=providers,
                error=f"Gemini error: {e}",
            )

        parsed = self._parse_json(text)
        if parsed is None:
            return self._fallback_response(
                user_message=user_message,
                providers=providers,
                error="Failed to parse Gemini JSON response.",
                raw=text,
            )
        return self._normalize(parsed)

    # ---------- helpers ----------

    def _build_prompt(
        self,
        user_message: str,
        providers: List[Dict[str, Any]],
        user_name: str,
        is_returning_user: bool,
        scenario_note: Optional[str],
    ) -> str:
        context_parts = [
            f"USER_NAME: {user_name or 'unknown'}",
            f"IS_RETURNING_USER: {is_returning_user}",
            f"USER_MESSAGE: {user_message}",
            f"PROVIDERS (JSON): {json.dumps(providers, ensure_ascii=False)}",
            f"RESPONSE_JSON_SCHEMA: {json.dumps(RESPONSE_SCHEMA_HINT, ensure_ascii=False)}",
        ]
        if scenario_note:
            context_parts.append(f"SCENARIO_NOTE: {scenario_note}")
        context_parts.append(
            "Return ONLY a single JSON object that matches the schema. "
            "Use PKR for all monetary fields. "
            "Exclude providers with Availability=false or cancellation rate > 15% "
            "from top_providers and recommended_provider. "
            "If no eligible provider exists, set recommended_provider to null and "
            "explain in booking_action."
        )
        return "\n\n".join(context_parts)

    def _parse_json(self, text: str) -> Optional[Dict[str, Any]]:
        text = text.strip()
        try:
            return json.loads(text)
        except Exception:
            pass
        # Strip markdown code fences if any
        fenced = re.search(r"```(?:json)?\s*(\{.*\})\s*```", text, re.DOTALL)
        if fenced:
            try:
                return json.loads(fenced.group(1))
            except Exception:
                pass
        # Try first {...} block
        brace = re.search(r"\{.*\}", text, re.DOTALL)
        if brace:
            try:
                return json.loads(brace.group(0))
            except Exception:
                pass
        return None

    def _normalize(self, data: Dict[str, Any]) -> Dict[str, Any]:
        defaults = {
            "confidence_score": 0,
            "clarification_needed": False,
            "clarification_question": "",
            "extracted_intent": {
                "service_type": None,
                "location": None,
                "preferred_time": None,
                "urgency": None,
                "budget_sensitivity": None,
            },
            "top_providers": [],
            "ranking_factors": {
                "specialization": 0,
                "availability": 0,
                "reliability": 0,
                "distance": 0,
                "rating": 0,
                "price": 0,
            },
            "recommended_provider": None,
            "price_quote": {
                "base_fee": 0,
                "distance_adjustment": 0,
                "urgency_surcharge": 0,
                "loyalty_discount": 0,
                "total": 0,
                "breakdown_explanation": "",
            },
            "booking_action": "",
            "agent_reasoning_trace": [],
        }
        for k, v in defaults.items():
            if k not in data or data[k] is None:
                data[k] = v
            elif isinstance(v, dict) and isinstance(data[k], dict):
                for sk, sv in v.items():
                    data[k].setdefault(sk, sv)
        return data

    def _fallback_response(
        self,
        user_message: str,
        providers: List[Dict[str, Any]],
        error: str,
        raw: str = "",
    ) -> Dict[str, Any]:
        return self._normalize(
            {
                "confidence_score": 0,
                "clarification_needed": True,
                "clarification_question": (
                    "Sorry, I could not understand your request. "
                    "Could you please describe the service you need and your area?"
                ),
                "agent_reasoning_trace": [
                    f"Agent fallback triggered: {error}",
                    f"Raw model output: {raw[:300]}" if raw else "No raw output.",
                ],
                "booking_action": "No booking created due to agent error.",
            }
        )
