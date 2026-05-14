"""Google Sheets service using gspread and a service account.

Expected tabs:
    Providers: any provider columns (ProviderID, Name, Service, Area, HourlyRate,
               Availability, Rating, ReliabilityScore, CancellationRate, ...)
    Bookings:  BookingID, UserName, Service, Location, DateTime, ProviderID,
               ProviderName, Price, Status, Notes, CreatedAt, Rating, Feedback
"""

from __future__ import annotations

import os
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

import gspread
from google.oauth2.service_account import Credentials

SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive",
]

BOOKING_HEADERS = [
    "BookingID",
    "UserName",
    "Service",
    "Location",
    "DateTime",
    "ProviderID",
    "ProviderName",
    "Price",
    "Status",
    "Notes",
    "CreatedAt",
    "Rating",
    "Feedback",
]


class SheetsService:
    def __init__(
        self,
        sheet_id: Optional[str] = None,
        credentials_file: Optional[str] = None,
    ) -> None:
        self.sheet_id = sheet_id or os.getenv("GOOGLE_SHEET_ID")
        self.credentials_file = credentials_file or os.getenv(
            "GOOGLE_CREDENTIALS_FILE", "./credentials.json"
        )
        self._client: Optional[gspread.Client] = None
        self._spreadsheet = None

    # ---------- internal ----------

    def _get_client(self) -> gspread.Client:
        if self._client is None:
            if not self.credentials_file or not os.path.exists(self.credentials_file):
                raise FileNotFoundError(
                    f"Google credentials file not found at: {self.credentials_file}"
                )
            creds = Credentials.from_service_account_file(
                self.credentials_file, scopes=SCOPES
            )
            self._client = gspread.authorize(creds)
        return self._client

    def _get_spreadsheet(self):
        if self._spreadsheet is None:
            if not self.sheet_id:
                raise ValueError("GOOGLE_SHEET_ID is not configured.")
            self._spreadsheet = self._get_client().open_by_key(self.sheet_id)
        return self._spreadsheet

    def _get_or_create_worksheet(self, title: str, headers: Optional[List[str]] = None):
        ss = self._get_spreadsheet()
        try:
            ws = ss.worksheet(title)
        except gspread.WorksheetNotFound:
            ws = ss.add_worksheet(title=title, rows=1000, cols=max(20, len(headers or [])))
            if headers:
                ws.append_row(headers)
        # Ensure headers exist on Bookings tab
        if headers:
            try:
                first_row = ws.row_values(1)
                if not first_row:
                    ws.append_row(headers)
            except Exception:
                pass
        return ws

    # ---------- public API ----------

    def get_all_providers(self) -> List[Dict[str, Any]]:
        ws = self._get_or_create_worksheet("Providers")
        all_values = ws.get_all_values()
        if len(all_values) < 2:
            return []
        headers = all_values[0]
        records = []
        for row in all_values[1:]:
            record = {}
            for i, header in enumerate(headers):
                record[header] = row[i] if i < len(row) else ""
            records.append(record)
        # Normalize key fields commonly used by the agent
        normalized: List[Dict[str, Any]] = []
        for r in records:
            row = {k: v for k, v in r.items()}
            # Coerce availability to bool-friendly value
            avail = str(row.get("Available", row.get("Availability", ""))).strip().lower()
            row["Available"] = avail in ("true", "yes", "1", "available", "y")
            row["Availability"] = row["Available"]
            normalized.append(row)
        return normalized

    def create_booking(self, booking_data: Dict[str, Any]) -> Dict[str, Any]:
        ws = self._get_or_create_worksheet("Bookings", BOOKING_HEADERS)
        booking_id = booking_data.get("BookingID") or str(uuid.uuid4())
        created_at = datetime.utcnow().isoformat()

        row_dict = {
            "BookingID": booking_id,
            "UserName": booking_data.get("UserName", ""),
            "Service": booking_data.get("Service", ""),
            "Location": booking_data.get("Location", ""),
            "DateTime": booking_data.get("DateTime", ""),
            "ProviderID": booking_data.get("ProviderID", ""),
            "ProviderName": booking_data.get("ProviderName", ""),
            "Price": booking_data.get("Price", ""),
            "Status": booking_data.get("Status", "Confirmed"),
            "Notes": booking_data.get("Notes", ""),
            "CreatedAt": created_at,
            "Rating": "",
            "Feedback": "",
        }
        ws.append_row([row_dict[h] for h in BOOKING_HEADERS])
        return row_dict

    def _find_booking_row(self, booking_id: str):
        ws = self._get_or_create_worksheet("Bookings", BOOKING_HEADERS)
        try:
            cell = ws.find(booking_id, in_column=1)
        except gspread.exceptions.CellNotFound:
            return ws, None
        if cell is None:
            return ws, None
        return ws, cell.row

    def update_booking_status(self, booking_id: str, status: str) -> Dict[str, Any]:
        ws, row = self._find_booking_row(booking_id)
        if row is None:
            raise ValueError(f"Booking {booking_id} not found")
        status_col = BOOKING_HEADERS.index("Status") + 1
        ws.update_cell(row, status_col, status)
        return self.get_booking(booking_id)

    def update_booking_feedback(
        self, booking_id: str, rating: int, comment: str
    ) -> Dict[str, Any]:
        ws, row = self._find_booking_row(booking_id)
        if row is None:
            raise ValueError(f"Booking {booking_id} not found")
        rating_col = BOOKING_HEADERS.index("Rating") + 1
        feedback_col = BOOKING_HEADERS.index("Feedback") + 1
        ws.update_cell(row, rating_col, rating)
        ws.update_cell(row, feedback_col, comment or "")
        return self.get_booking(booking_id)

    def get_booking(self, booking_id: str) -> Optional[Dict[str, Any]]:
        ws, row = self._find_booking_row(booking_id)
        if row is None:
            return None
        values = ws.row_values(row)
        return {h: (values[i] if i < len(values) else "") for i, h in enumerate(BOOKING_HEADERS)}

    def find_bookings_by_session(self, session_id: str) -> List[Dict[str, Any]]:
        """Bookings track session_id inside the Notes column (prefixed)."""
        ws = self._get_or_create_worksheet("Bookings", BOOKING_HEADERS)
        all_values = ws.get_all_values()
        if len(all_values) < 2:
            return []
        headers = all_values[0]
        records = []
        for row in all_values[1:]:
            record = {}
            for i, header in enumerate(headers):
                record[header] = row[i] if i < len(row) else ""
            records.append(record)
        out = []
        for r in records:
            notes = str(r.get("Notes", ""))
            if f"session:{session_id}" in notes:
                out.append(r)
        return out
