import re


def clean_value(value: str):
    if not value:
        return None

    return re.sub(r"\s+", " ", value).strip(" .:-")


def extract_name(text: str):
    patterns = [
        r"awarded to\s+([A-Za-z\s.]+)",
        r"presented to\s+([A-Za-z\s.]+)",
        r"certifies that\s+([A-Za-z\s.]+)",
        r"this is to certify that\s+([A-Za-z\s.]+)",
        r"name[:\-]\s*([A-Za-z\s.]+)"
    ]

    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return clean_value(match.group(1))

    return None


def extract_designation(text: str):
    patterns = [
        r"designation[:\-]\s*([A-Za-z\s.]+)",
        r"role[:\-]\s*([A-Za-z\s.]+)",
        r"position[:\-]\s*([A-Za-z\s.]+)",
        r"as\s+(student|intern|developer|participant|winner|coordinator|volunteer|manager)"
    ]

    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return clean_value(match.group(1))

    return None


def extract_certificate_id(text: str):
    patterns = [
        r"certificate\s*(id|no|number)[:\-]?\s*([A-Z0-9\-\/]+)",
        r"cert\s*(id|no)[:\-]?\s*([A-Z0-9\-\/]+)",
        r"id[:\-]\s*([A-Z0-9\-\/]+)"
    ]

    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return clean_value(match.group(2))

    return None


def extract_date(text: str):
    patterns = [
        r"\b\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}\b",
        r"\b\d{1,2}\s+(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4}\b",
        r"\b\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}\b",
        r"\b(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},?\s+\d{4}\b"
    ]

    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return clean_value(match.group(0))

    return None


def extract_issuer(text: str):
    patterns = [
        r"issued by\s+([A-Za-z\s.&]+)",
        r"organized by\s+([A-Za-z\s.&]+)",
        r"institution[:\-]\s*([A-Za-z\s.&]+)",
        r"organization[:\-]\s*([A-Za-z\s.&]+)"
    ]

    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return clean_value(match.group(1))

    return None


def parse_certificate_text(text: str):
    return {
        "name": extract_name(text),
        "designation": extract_designation(text),
        "certificate_id": extract_certificate_id(text),
        "date": extract_date(text),
        "issuer": extract_issuer(text),
    }