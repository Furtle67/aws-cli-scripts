import boto3
import json
from datetime import datetime, timezone

# ── Config ────────────────────────────────────────────────────────────────────
LOG_GROUP   = "/aws/transfer/pfe-sftp-nv-sftp"   # e.g. /aws/transfer/s-xxxxxxxxxx
REGION      = "us-east-1"
PROFILE     = "pfizer"
START_TIME  = int(datetime(2025, 1, 1, tzinfo=timezone.utc).timestamp() * 1000)  # ms
END_TIME    = int(datetime.now(timezone.utc).timestamp() * 1000)                 # ms
# ─────────────────────────────────────────────────────────────────────────────

session = boto3.Session(profile_name=PROFILE, region_name=REGION)
client = session.client("logs")


def get_log_streams(log_group: str) -> list[str]:
    """Return all stream names in the log group."""
    streams, token = [], None
    while True:
        kwargs = {"logGroupName": log_group, "orderBy": "LastEventTime", "descending": True}
        if token:
            kwargs["nextToken"] = token
        resp = client.describe_log_streams(**kwargs)
        streams += [s["logStreamName"] for s in resp.get("logStreams", [])]
        token = resp.get("nextToken")
        if not token:
            break
    return streams


def fetch_events(log_group: str, stream: str) -> list[dict]:
    """Fetch raw log events from a single stream."""
    events, token = [], None
    while True:
        kwargs = {
            "logGroupName":  log_group,
            "logStreamName": stream,
            "startTime":     START_TIME,
            "endTime":       END_TIME,
            "startFromHead": True,
        }
        if token:
            kwargs["nextToken"] = token
        resp = client.get_log_events(**kwargs)
        batch = resp.get("events", [])
        events += batch
        token = resp.get("nextToken")
        # CloudWatch returns the same token when exhausted
        if not batch or token == kwargs.get("nextToken"):
            break
    return events


def parse_event(raw_event: dict) -> dict | None:
    """
    Extract time, user, and activity type from a CloudWatch log event.

    AWS Transfer logs look like:
    {
      "type":      "OPEN" | "CLOSE" | "READ" | "WRITE" | "DELETE" | "RENAME" | ...,
      "details":   { "username": "alice", ... },
      "timestamp": "2025-03-15T12:34:56.000Z",   # sometimes present
      ...
    }
    The CloudWatch envelope also carries a millisecond timestamp.
    """
    try:
        msg = json.loads(raw_event["message"])
    except (json.JSONDecodeError, KeyError):
        return None  # skip malformed lines

    # Timestamp: prefer field inside JSON, fall back to CloudWatch envelope (ms)
    ts_raw = msg.get("timestamp") or msg.get("time")
    if ts_raw:
        time_str = ts_raw
    else:
        ts_ms = raw_event.get("timestamp", 0)
        time_str = datetime.fromtimestamp(ts_ms / 1000, tz=timezone.utc).isoformat()

    # User: nested under "details" in Transfer Family structured logs
    details  = msg.get("details", {})
    user     = (
        details.get("username")
        or details.get("user")
        or msg.get("username")
        or msg.get("user")
        or "unknown"
    )

    # Activity type
    activity = (
        msg.get("type")
        or msg.get("activity")
        or msg.get("eventType")
        or msg.get("operation")
        or "unknown"
    )

    return {"time": time_str, "user": user, "activity": activity}


def main():
    print(f"Fetching streams from log group: {LOG_GROUP}\n")
    streams = get_log_streams(LOG_GROUP)
    print(f"Found {len(streams)} stream(s)\n")

    results = []
    for stream in streams:
        events = fetch_events(LOG_GROUP, stream)
        for raw in events:
            parsed = parse_event(raw)
            if parsed:
                results.append(parsed)

    # ── Output ────────────────────────────────────────────────────────────────
    print(f"{'Time':<35} {'User':<20} {'Activity'}")
    print("-" * 75)
    for r in sorted(results, key=lambda x: x["time"]):
        print(f"{r['time']:<35} {r['user']:<20} {r['activity']}")

    # Optional: save to JSON
    with open("transfer_log_parsed.json", "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nSaved {len(results)} events → transfer_log_parsed.json")


if __name__ == "__main__":
    main()