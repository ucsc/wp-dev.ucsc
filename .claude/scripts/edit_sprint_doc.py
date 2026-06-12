#!/usr/bin/env python3
"""
Edit the One Week Sprint Model Google Doc via the Docs API.
Uses batchUpdate for surgical text edits: find text, insert at position, replace.

Usage:
  edit_sprint_doc.py --read                  # dump doc text to stdout
  edit_sprint_doc.py --read --section "Week After"  # dump a specific section
  edit_sprint_doc.py --apply                 # apply all pending edits
  edit_sprint_doc.py --apply --dry-run       # show what would change without writing
"""

import json
import os
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
SERVICE_ACCOUNT_FILE = SCRIPT_DIR / "service_account.json"
CREDENTIALS_FILE = SCRIPT_DIR / "credentials.json"
TOKEN_FILE = SCRIPT_DIR / "token.json"

DOC_ID = "1WrVXB4ZMOwGVkx5lzN_kkBfqS91hCFR6ZKA9d9hiaDs"

SCOPES = [
    "https://www.googleapis.com/auth/documents",
    "https://www.googleapis.com/auth/drive.readonly",
]


def ensure_venv():
    if sys.prefix != sys.base_prefix:
        return
    venv_dir = SCRIPT_DIR / ".venv"
    venv_python = venv_dir / "bin" / "python"
    if not venv_dir.exists():
        print("[INFO] Creating virtual environment...")
        import subprocess
        subprocess.check_call([sys.executable, "-m", "venv", str(venv_dir)])
    print("[INFO] Re-running inside venv...")
    import subprocess
    sys.exit(subprocess.call([str(venv_python)] + sys.argv))


def authenticate():
    try:
        from google.oauth2 import service_account as sa_mod
        from google.auth.transport.requests import Request
        from google.oauth2.credentials import Credentials
        from googleapiclient.discovery import build
    except ImportError:
        import subprocess
        subprocess.check_call([
            sys.executable, "-m", "pip", "install",
            "google-api-python-client", "google-auth-httplib2", "google-auth-oauthlib",
        ])
        from google.oauth2 import service_account as sa_mod
        from google.auth.transport.requests import Request
        from google.oauth2.credentials import Credentials
        from googleapiclient.discovery import build

    gcloud_adc = Path("/Users/henryh/.config/gcloud/application_default_credentials.json")
    if gcloud_adc.exists():
        try:
            os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(gcloud_adc)
            import google.auth
            creds, _ = google.auth.default(scopes=SCOPES)
            docs = build("docs", "v1", credentials=creds)
            docs.documents().get(documentId=DOC_ID, fields="title").execute()
            print("[OK] Authenticated via gcloud ADC")
            return docs
        except Exception as e:
            print(f"[INFO] gcloud ADC failed: {e}")

    if SERVICE_ACCOUNT_FILE.exists():
        creds = sa_mod.Credentials.from_service_account_file(
            str(SERVICE_ACCOUNT_FILE), scopes=SCOPES
        )
        docs = build("docs", "v1", credentials=creds)
        print("[OK] Authenticated via service account")
        return docs

    if CREDENTIALS_FILE.exists() or TOKEN_FILE.exists():
        from google_auth_oauthlib.flow import InstalledAppFlow
        creds = None
        if TOKEN_FILE.exists():
            creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)
        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(Request())
            else:
                flow = InstalledAppFlow.from_client_secrets_file(str(CREDENTIALS_FILE), SCOPES)
                creds = flow.run_local_server(port=0)
            TOKEN_FILE.write_text(creds.to_json())
        docs = build("docs", "v1", credentials=creds)
        print("[OK] Authenticated via OAuth")
        return docs

    print("[ERROR] No credentials found. Place service_account.json next to this script,")
    print("        or run: gcloud auth application-default login --scopes=https://www.googleapis.com/auth/documents,https://www.googleapis.com/auth/drive.readonly")
    sys.exit(1)


def extract_text(doc):
    """Return the full plain text of the document and a map of paragraph styles."""
    body = doc.get("body", {}).get("content", [])
    full_text = ""
    paragraphs = []
    for element in body:
        if "paragraph" in element:
            para = element["paragraph"]
            style = para.get("paragraphStyle", {}).get("namedStyleType", "NORMAL_TEXT")
            start = element.get("startIndex", 0)
            end = element.get("endIndex", 0)
            text = ""
            for el in para.get("elements", []):
                tr = el.get("textRun", {})
                text += tr.get("content", "")
            full_text += text
            paragraphs.append({"style": style, "start": start, "end": end, "text": text})
    return full_text, paragraphs


def find_text_index(full_text, needle):
    """Find the character index of needle in the document text."""
    idx = full_text.find(needle)
    if idx == -1:
        return None
    return idx


def build_edits(full_text, paragraphs):
    """
    Build the list of batchUpdate requests for all pending edits.
    Returns (requests_list, descriptions) — both lists aligned by index.

    IMPORTANT: Docs API indices shift when you insert/delete text.
    We build all edits referencing the CURRENT document state,
    then sort them in REVERSE index order so earlier inserts don't
    shift later ones.
    """
    edits = []

    # --- Edit 1: Fix "commitments.Tuesday" junction ---
    # The capacity paragraph ran into the Tuesday heading without a line break.
    junction = "missed commitments.Tuesday:"
    idx = find_text_index(full_text, junction)
    if idx is not None:
        insert_at = idx + len("missed commitments.")
        edits.append({
            "desc": "Fix commitments/Tuesday junction: insert paragraph break",
            "index": insert_at,
            "ops": [
                {"insertText": {"location": {"index": insert_at}, "text": "\n"}},
            ],
        })
    else:
        print("[SKIP] 'commitments.Tuesday' junction not found (may already be fixed)")

    # --- Edit 2: Fix "session.Work" junction in Daily Standup ---
    junction2 = "session.Work"
    idx2 = find_text_index(full_text, junction2)
    if idx2 is not None:
        insert_at2 = idx2 + len("session.")
        edits.append({
            "desc": "Fix session/Work junction: insert space",
            "index": insert_at2,
            "ops": [
                {"insertText": {"location": {"index": insert_at2}, "text": " "}},
            ],
        })
    else:
        print("[SKIP] 'session.Work' junction not found (may already be fixed)")

    # --- Edit 3: Add story points text after capacity paragraph ---
    anchor = "Planning for the full 40 hours will consistently result in missed commitments."
    idx3 = find_text_index(full_text, anchor)
    if idx3 is not None:
        insert_at3 = idx3 + len(anchor)
        story_points_text = (
            " Teams that use story points rather than hours for estimation "
            "should calibrate their velocity against this adjusted capacity, "
            "not the raw 40 hour total. Story points abstract away individual "
            "variation and make sprint planning more predictable over time, "
            "but the underlying constraint remains the same: a one week sprint "
            "offers roughly 24 to 28 productive hours per developer."
        )
        edits.append({
            "desc": "Add story points guidance to capacity paragraph",
            "index": insert_at3,
            "ops": [
                {"insertText": {"location": {"index": insert_at3}, "text": story_points_text}},
            ],
        })
    else:
        print("[SKIP] Capacity anchor text not found (may already include story points)")

    # --- Edit 4: Add sprint ceremonies mention ---
    # Insert after the Monday kickoff closing paragraph.
    ceremonies_anchor = "The kickoff should be brief because major planning decisions should already be complete before the sprint starts."
    idx4 = find_text_index(full_text, ceremonies_anchor)
    if idx4 is not None:
        insert_at4 = idx4 + len(ceremonies_anchor)
        ceremonies_text = (
            "\n\nThe one week sprint follows the standard set of Agile ceremonies: "
            "sprint planning (week before), sprint kickoff (Monday), daily standups "
            "(Tuesday through Friday), sprint review (Friday), and sprint retrospective "
            "(Friday). These ceremonies provide the rhythm and accountability structure "
            "that keeps the compressed timeline on track."
        )
        edits.append({
            "desc": "Add sprint ceremonies paragraph after kickoff section",
            "index": insert_at4,
            "ops": [
                {"insertText": {"location": {"index": insert_at4}, "text": ceremonies_text}},
            ],
        })
    else:
        print("[SKIP] Kickoff anchor text not found")

    # --- Edit 5: Tighten "Week After" section ---
    # Replace the opening of the Week After section to frame it as exception, not rule.
    week_after_old = "The week after the sprint is used for"
    idx5 = find_text_index(full_text, week_after_old)
    if idx5 is not None:
        # Find the end of this sentence (next period)
        sentence_end = full_text.find(".", idx5)
        if sentence_end != -1:
            old_sentence = full_text[idx5 : sentence_end + 1]
            new_sentence = (
                "The week after the sprint is not a continuation of development. "
                "It exists strictly as a buffer for release verification, hotfix response, "
                "and operational handoff. Work that was not completed during the sprint "
                "returns to the backlog for reprioritization, it does not carry over automatically. "
                "If a team routinely relies on the week after to finish sprint work, "
                "that is a planning problem, not a scheduling feature."
            )
            edits.append({
                "desc": "Tighten 'Week After' opening: frame as exception not rule",
                "index": idx5,
                "ops": [
                    {
                        "replaceAllText": {
                            "containsText": {"text": old_sentence, "matchCase": True},
                            "replaceText": new_sentence,
                        }
                    },
                ],
            })
    else:
        print("[SKIP] 'Week After' opening text not found")

    return edits


def apply_edits(docs, edits, dry_run=False):
    """Apply edits to the document. Sorts by index descending so inserts don't shift."""
    # Separate positional edits from replaceAllText edits
    positional = [e for e in edits if not any("replaceAllText" in op for op in e["ops"])]
    global_replacements = [e for e in edits if any("replaceAllText" in op for op in e["ops"])]

    # Sort positional edits by index descending
    positional.sort(key=lambda e: e["index"], reverse=True)

    # Build the requests list: positional first (reverse order), then global replacements
    requests = []
    for edit in positional:
        for op in edit["ops"]:
            requests.append(op)
    for edit in global_replacements:
        for op in edit["ops"]:
            requests.append(op)

    all_edits = positional + global_replacements
    print(f"\n{'[DRY RUN] ' if dry_run else ''}Planned edits ({len(all_edits)}):")
    for i, edit in enumerate(all_edits, 1):
        print(f"  {i}. {edit['desc']}")

    if dry_run:
        print("\n[DRY RUN] No changes written.")
        return

    if not requests:
        print("\n[INFO] No edits to apply.")
        return

    print(f"\nApplying {len(requests)} operations...")
    result = docs.documents().batchUpdate(
        documentId=DOC_ID,
        body={"requests": requests},
    ).execute()
    print(f"[OK] Applied {len(result.get('replies', []))} operations successfully.")


def read_doc(docs, section_filter=None):
    """Read and print document text, optionally filtered to a section."""
    doc = docs.documents().get(documentId=DOC_ID).execute()
    print(f"Title: {doc.get('title')}\n")
    full_text, paragraphs = extract_text(doc)

    if section_filter:
        in_section = False
        for p in paragraphs:
            if section_filter.lower() in p["text"].lower() and "HEADING" in p["style"]:
                in_section = True
            elif in_section and "HEADING" in p["style"]:
                break
            if in_section:
                style_tag = p["style"].replace("HEADING_", "H").replace("NORMAL_TEXT", "")
                prefix = f"[{style_tag}] " if style_tag else ""
                print(f"{prefix}{p['text']}", end="")
    else:
        for p in paragraphs:
            style_tag = p["style"].replace("HEADING_", "H").replace("NORMAL_TEXT", "")
            prefix = f"[{style_tag}] " if style_tag else ""
            print(f"{prefix}{p['text']}", end="")


def main():
    ensure_venv()

    args = sys.argv[1:]
    mode = None
    section = None
    dry_run = "--dry-run" in args

    if "--read" in args:
        mode = "read"
        if "--section" in args:
            idx = args.index("--section")
            if idx + 1 < len(args):
                section = args[idx + 1]
    elif "--apply" in args:
        mode = "apply"
    else:
        print(__doc__)
        sys.exit(0)

    docs = authenticate()

    if mode == "read":
        read_doc(docs, section_filter=section)
    elif mode == "apply":
        doc = docs.documents().get(documentId=DOC_ID).execute()
        full_text, paragraphs = extract_text(doc)
        edits = build_edits(full_text, paragraphs)
        if not edits:
            print("[INFO] No applicable edits found.")
            return
        apply_edits(docs, edits, dry_run=dry_run)


if __name__ == "__main__":
    main()
