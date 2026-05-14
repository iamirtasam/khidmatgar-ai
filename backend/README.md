# ServiceOrchestrator Backend

AI-powered FastAPI backend for Pakistan's informal economy service orchestrator
(plumbers, electricians, AC technicians, etc.). Uses Google Gemini for intent
extraction + provider ranking, and Google Sheets as the data store.

## Setup

1. **Python 3.10+** recommended.

2. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

3. Create a `.env` file (copy from `.env.example`) and fill in:

   ```
   GEMINI_API_KEY=...
   GOOGLE_SHEET_ID=...
   GOOGLE_CREDENTIALS_FILE=./credentials.json
   ```

4. Put your Google service account JSON at the path you set in
   `GOOGLE_CREDENTIALS_FILE`. Share your Google Sheet with the service account
   email (Editor access).

5. The target Google Sheet should contain two tabs:

   - **Providers** — columns such as:
     `ProviderID, Name, Service, Area, HourlyRate, Availability, Rating,
     ReliabilityScore, CancellationRate, ExperienceYears, Phone`
   - **Bookings** — will be auto-created with the headers:
     `BookingID, UserName, Service, Location, DateTime, ProviderID,
     ProviderName, Price, Status, Notes, CreatedAt, Rating, Feedback`

## Run

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Open Swagger UI at: <http://localhost:8000/docs>

## Endpoints

- `POST /chat` — main agent entry point
- `POST /confirm-booking` — confirm/cancel the pending booking for a session
- `POST /feedback` — submit rating + comment for a booking
- `GET  /providers` — list all providers
- `GET  /booking/{booking_id}` — fetch booking by ID
- `POST /stress-test/no-provider` — simulate all providers unavailable
- `POST /stress-test/cancellation` — simulate provider cancellation + reassign

CORS is open to all origins for Flutter web development.
