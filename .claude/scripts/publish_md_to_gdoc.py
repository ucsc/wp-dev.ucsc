#!/usr/bin/env python3
"""
Publish a Markdown file to a Google Doc via the Drive API.

Usage:
  publish_md_to_gdoc.py <markdown_file> --doc <google_doc_url_or_id>
  publish_md_to_gdoc.py <markdown_file> --doc <url> --credentials <path_to_service_account.json>
  publish_md_to_gdoc.py <markdown_file> --doc <url> --backup

Examples:
  publish_md_to_gdoc.py one_week_sprint_model.md --doc https://docs.google.com/document/d/1WrV.../edit
  publish_md_to_gdoc.py README.md --doc 1WrVXB4ZMOwGVkx5lzN_kkBfqS91hCFR6ZKA9d9hiaDs
  publish_md_to_gdoc.py slides.md --doc <url> --credentials ~/.config/gcp/my-sa.json --backup

Options:
  --doc          Google Doc URL or document ID (required)
  --credentials  Path to service account JSON (default: service_account.json next to this script)
  --backup       Export the current Google Doc as HTML before overwriting (saved next to the markdown file)
  --dry-run      Convert and show the HTML without uploading
"""

import os
import sys
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent


def ensure_venv():
    if sys.prefix != sys.base_prefix:
        return
    venv_dir = SCRIPT_DIR / ".venv"
    venv_python = venv_dir / "bin" / "python"
    if not venv_dir.exists():
        print("[INFO] Creating virtual environment...")
        import subprocess
        subprocess.check_call([sys.executable, "-m", "venv", str(venv_dir)])
    import subprocess
    sys.exit(subprocess.call([str(venv_python)] + sys.argv))


def parse_doc_id(raw):
    if "docs.google.com/document/d/" in raw:
        doc_id = raw.split("/document/d/")[1].split("/")[0].split("?")[0]
        return doc_id
    return raw


def parse_args():
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help"):
        print(__doc__)
        sys.exit(0)

    md_file = Path(args[0])
    doc_id = None
    credentials = SCRIPT_DIR / "service_account.json"
    backup = False
    dry_run = False

    i = 1
    while i < len(args):
        if args[i] == "--doc" and i + 1 < len(args):
            doc_id = parse_doc_id(args[i + 1])
            i += 2
        elif args[i] == "--credentials" and i + 1 < len(args):
            credentials = Path(args[i + 1]).expanduser()
            i += 2
        elif args[i] == "--backup":
            backup = True
            i += 1
        elif args[i] == "--dry-run":
            dry_run = True
            i += 1
        else:
            print(f"[ERROR] Unknown argument: {args[i]}")
            print(__doc__)
            sys.exit(1)

    if not md_file.exists():
        print(f"[ERROR] Markdown file not found: {md_file}")
        sys.exit(1)
    if not doc_id:
        print("[ERROR] --doc is required")
        print(__doc__)
        sys.exit(1)

    return md_file, doc_id, credentials, backup, dry_run


def convert_md_to_html(md_path):
    try:
        import markdown
    except ImportError:
        import subprocess
        subprocess.check_call([sys.executable, "-m", "pip", "install", "markdown"])
        import markdown

    md_content = md_path.read_text()

    # Strip Marp frontmatter if present
    if md_content.startswith("---"):
        parts = md_content.split("---", 2)
        if len(parts) >= 3:
            md_content = parts[2]
        md_content = md_content.replace("\n---\n", "\n<hr />\n")

    html_body = markdown.markdown(md_content, extensions=["extra", "tables"])

    # Fix newlines inside <pre> blocks for Google Docs
    import re
    def replace_pre_newlines(match):
        return match.group(0).replace("\n", "<br />\n")
    html_body = re.sub(r"<pre>.*?</pre>", replace_pre_newlines, html_body, flags=re.DOTALL)

    # Strip language classes from <code> tags
    html_body = re.sub(r'<code class="language-[^"]+">', "<code>", html_body)

    html_document = """<!DOCTYPE html>
<html><head><meta charset="utf-8">
<style>
  body { font-family: Arial, sans-serif; line-height: 1.5; color: #333333; }
  h1 { color: #0f4c81; border-bottom: 1px solid #cccccc; padding-bottom: 5px; margin-top: 30px; }
  h2 { color: #1e293b; margin-top: 25px; }
  h3 { color: #475569; }
  ul { margin: 10px 0; }
  li { margin: 4px 0; }
  table { border-collapse: collapse; width: 100%; margin: 20px 0; }
  th, td { border: 1px solid #dddddd; text-align: left; padding: 8px; }
  th { background-color: #f2f2f2; font-weight: bold; }
  code { background-color: #f1f5f9; padding: 2px 4px; font-family: monospace; font-size: 0.9em; }
  pre { background-color: #f1f5f9; padding: 10px; border: 1px solid #e2e8f0; overflow-x: auto; }
  pre code { background-color: transparent; padding: 0; }
  hr { border: 0; border-top: 2px solid #0f4c81; margin: 40px 0; }
  strong { font-weight: bold; }
  em { font-style: italic; }
</style>
</head><body>""" + html_body + """</body></html>"""

    return html_document


def authenticate(credentials_path):
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

    SCOPES = ["https://www.googleapis.com/auth/drive"]

    # Method 1: gcloud ADC
    gcloud_adc = Path("/Users/henryh/.config/gcloud/application_default_credentials.json")
    if gcloud_adc.exists():
        try:
            os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(gcloud_adc)
            import google.auth
            creds, _ = google.auth.default(scopes=SCOPES)
            service = build("drive", "v3", credentials=creds)
            service.files().list(pageSize=1).execute()
            print("[OK] Authenticated via gcloud ADC")
            return service
        except Exception:
            pass

    # Method 2: Service account
    if credentials_path.exists():
        creds = sa_mod.Credentials.from_service_account_file(
            str(credentials_path), scopes=SCOPES
        )
        print("[OK] Authenticated via service account")
        return build("drive", "v3", credentials=creds)

    # Method 3: OAuth token
    token_file = SCRIPT_DIR / "token.json"
    creds_file = SCRIPT_DIR / "credentials.json"
    if token_file.exists() or creds_file.exists():
        from google_auth_oauthlib.flow import InstalledAppFlow
        creds = None
        if token_file.exists():
            creds = Credentials.from_authorized_user_file(str(token_file), SCOPES)
        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(Request())
            else:
                flow = InstalledAppFlow.from_client_secrets_file(str(creds_file), SCOPES)
                creds = flow.run_local_server(port=0)
            token_file.write_text(creds.to_json())
        print("[OK] Authenticated via OAuth")
        return build("drive", "v3", credentials=creds)

    print("[ERROR] No credentials found.")
    print(f"  Place a service account JSON at: {credentials_path}")
    print("  Or run: gcloud auth application-default login --scopes=https://www.googleapis.com/auth/drive")
    sys.exit(1)


def backup_doc(drive, doc_id, md_path):
    from googleapiclient.http import MediaIoBaseDownload
    import io

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = md_path.parent / f"{md_path.stem}_backup_{timestamp}.html"

    request = drive.files().export_media(fileId=doc_id, mimeType="text/html")
    fh = io.BytesIO()
    downloader = MediaIoBaseDownload(fh, request)
    done = False
    while not done:
        _, done = downloader.next_chunk()
    backup_path.write_bytes(fh.getvalue())
    print(f"[OK] Backup saved: {backup_path}")
    return backup_path


def main():
    ensure_venv()

    md_file, doc_id, credentials, backup, dry_run = parse_args()

    print(f"Source:   {md_file}")
    print(f"Doc ID:   {doc_id}")

    html_content = convert_md_to_html(md_file)
    print(f"[OK] Converted {md_file.name} to HTML ({len(html_content)} bytes)")

    if dry_run:
        preview_path = md_file.parent / f"{md_file.stem}_preview.html"
        preview_path.write_text(html_content)
        print(f"[DRY RUN] Preview saved: {preview_path}")
        return

    drive = authenticate(credentials)

    if backup:
        backup_doc(drive, doc_id, md_file)

    from googleapiclient.http import MediaFileUpload

    temp_path = md_file.parent / f".{md_file.stem}_upload.html"
    temp_path.write_text(html_content)

    try:
        media = MediaFileUpload(str(temp_path), mimetype="text/html", resumable=True)
        result = drive.files().update(
            fileId=doc_id,
            media_body=media,
            fields="id,webViewLink",
        ).execute()
        link = result.get("webViewLink")
        print(f"[OK] Published: {link}")
    finally:
        if temp_path.exists():
            temp_path.unlink()


if __name__ == "__main__":
    main()
