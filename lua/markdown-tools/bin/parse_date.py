#!/usr/bin/env python3
"""Parse natural language date/time strings into structured JSON."""

import json
import sys
from datetime import datetime, timedelta

from dateutil import parser as dateparser
from dateutil.relativedelta import relativedelta, MO, TU, WE, TH, FR, SA, SU

WEEKDAYS = {"monday": MO, "tuesday": TU, "wednesday": WE, "thursday": TH,
             "friday": FR, "saturday": SA, "sunday": SU}

def resolve_relative(text):
    """Handle 'today', 'tomorrow', 'next tuesday', etc."""
    now = datetime.now()
    lower = text.lower().strip()

    if lower == "today":
        return now
    if lower == "tomorrow":
        return now + timedelta(days=1)

    # "next monday", "next friday", etc.
    for name, weekday in WEEKDAYS.items():
        if lower == name or lower == f"next {name}":
            return now + relativedelta(weekday=weekday(+1))

    # Fall back to dateutil
    return dateparser.parse(text, fuzzy=True)


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No input provided"}))
        sys.exit(1)

    text = " ".join(sys.argv[1:])

    # Split on last time-range pattern (e.g., "3pm-4pm")
    # Try to find a time range at the end
    import re
    time_pattern = r'(\d{1,2}(?::\d{2})?(?:am|pm|a|p)?)\s*-\s*(\d{1,2}(?::\d{2})?(?:am|pm|a|p)?)\s*$'
    match = re.search(time_pattern, text, re.IGNORECASE)

    if not match:
        print(json.dumps({"error": "No time range found (e.g., 3pm-4pm)"}))
        sys.exit(1)

    date_part = text[:match.start()].strip()
    start_str = match.group(1)
    end_str = match.group(2)

    # Parse date
    if date_part:
        try:
            dt = resolve_relative(date_part)
            if dt is None:
                print(json.dumps({"error": f"Could not parse date: {date_part}"}))
                sys.exit(1)
        except (ValueError, OverflowError):
            print(json.dumps({"error": f"Could not parse date: {date_part}"}))
            sys.exit(1)
    else:
        dt = datetime.now()

    date_str = dt.strftime("%Y-%m-%d")

    print(json.dumps({
        "date": date_str,
        "start_time": start_str,
        "end_time": end_str,
    }))


if __name__ == "__main__":
    main()
