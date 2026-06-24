#!/usr/bin/env python3
"""
Convert markdown slides to HTML and upload them to Google Drive as a Google Doc.
Supports both Service Account credentials (headless) and Desktop OAuth flow.
Shares the created Google Doc with the author's email.
"""

import json
import os
import sys
from pathlib import Path

# Target paths
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
SLIDES_PATH = (
    PROJECT_ROOT
    / ".claude"
    / "plugins"
    / "ucsc-wp-block-dev"
    / "skills"
    / "maintainer"
    / "assets"
    / "ucsc-wp-block-dev-presentation.md"
)
SERVICE_ACCOUNT_FILE = SCRIPT_DIR / "service_account.json"
CREDENTIALS_FILE = SCRIPT_DIR / "credentials.json"
TOKEN_FILE = SCRIPT_DIR / "token.json"

INSTRUCTIONS = f"""
========================================================================
[SETUP REQUIRED] Google API Credentials Needed
========================================================================
To publish directly to Google Docs, please complete one of the options below.

------------------------------------------------------------------------
OPTION A: gcloud Login (Easiest - Uses your existing gcloud setup)
------------------------------------------------------------------------
Your gcloud credentials are authenticated, but they lack the scope to access 
Google Drive. You can easily fix this by re-running login with the Drive scope:

  gcloud auth application-default login \\
      --scopes=https://www.googleapis.com/auth/drive,https://www.googleapis.com/auth/cloud-platform

Once you log in via the browser, simply re-run this script!

------------------------------------------------------------------------
OPTION B: Service Account (Headless, no browser login required)
------------------------------------------------------------------------
1. Go to the Google Cloud Console:
   https://console.cloud.google.com/
2. Select or create a project (e.g., "Doc Publisher").
3. Go to "APIs & Services" > "Library". Enable both "Google Drive API" 
   and "Google Docs API".
4. Go to "APIs & Services" > "Credentials".
5. Click "+ CREATE CREDENTIALS" > "Service account".
6. Fill in details (e.g., name: "doc-uploader"), click "Create and Continue",
   then click "Done".
7. In the credentials list, click on the email of the Service Account you 
   just created.
8. Go to the "Keys" tab, click "ADD KEY" > "Create new key".
9. Choose "JSON", click "Create", and save the downloaded file exactly to:
   {SERVICE_ACCOUNT_FILE}

------------------------------------------------------------------------
OPTION C: Desktop OAuth Client (Requires Chrome login authentication)
------------------------------------------------------------------------
1. Follow steps 1-3 above to enable the Google Drive and Google Docs APIs.
2. Go to "APIs & Services" > "OAuth consent screen". Choose "External" 
   and click "Create". Add your email, click Save. Under "Test users", 
   add your email.
3. Go to "APIs & Services" > "Credentials". Click "+ CREATE CREDENTIALS"
   > "OAuth client ID".
4. Application Type: "Desktop app". Click "Create".
5. Click the Download icon next to the client ID, and save the JSON file to:
   {CREDENTIALS_FILE}

========================================================================
"""

def print_instructions_and_exit():
    print(INSTRUCTIONS)
    sys.exit(0)

def ensure_venv():
    # Check if we are already in the virtual environment
    if sys.prefix != sys.base_prefix:
        return  # Already in a virtual environment
        
    venv_dir = SCRIPT_DIR / ".venv"
    venv_python = venv_dir / "bin" / "python"
    
    if not venv_dir.exists():
        print("[INFO] Creating virtual environment for Google API libraries...")
        import subprocess
        try:
            subprocess.check_call([sys.executable, "-m", "venv", str(venv_dir)])
            print("[INFO] Virtual environment created successfully.")
        except Exception as e:
            print(f"[ERROR] Failed to create virtual environment: {e}", file=sys.stderr)
            sys.exit(1)
            
    # Re-run this script using the venv python interpreter
    print("[INFO] Re-running script inside the virtual environment...")
    import subprocess
    args = [str(venv_python)] + sys.argv
    sys.exit(subprocess.call(args))

def get_user_email():
    manifest_path = PROJECT_ROOT / ".claude" / "plugins" / "ucsc-wp-block-dev" / ".claude-plugin" / "plugin.json"
    if manifest_path.exists():
        try:
            data = json.loads(manifest_path.read_text())
            email = data.get("author", {}).get("email")
            if email:
                return email
        except Exception:
            pass
    return "henryh@ucsc.edu"

def convert_md_to_html(md_path):
    if not md_path.exists():
        print(f"[ERROR] Slide file not found at {md_path}", file=sys.stderr)
        sys.exit(1)
        
    try:
        import markdown
    except ImportError:
        print("[INFO] 'markdown' package not installed. Installing it now...")
        import subprocess
        subprocess.check_call([sys.executable, "-m", "pip", "install", "markdown"])
        import markdown
        
    md_content = md_path.read_text()
    
    # Strip Marp frontmatter from the beginning if present
    if md_content.startswith("---"):
        parts = md_content.split("---", 2)
        if len(parts) >= 3:
            md_content = parts[2]
            
    # Simple substitution for Marp slide breaks ---
    md_content = md_content.replace("\n---\n", "\n<hr />\n")
    
    # Convert markdown to HTML
    html_body = markdown.markdown(md_content, extensions=['extra', 'tables'])
    
    # Google Docs HTML importer collapses newlines inside <pre> elements.
    # To fix this, we replace newlines (\n) inside <pre>...</pre> blocks with <br />.
    import re
    def replace_pre_newlines(match):
        pre_content = match.group(0)
        # Avoid double-breaking if already processed
        return pre_content.replace("\n", "<br />\n")
        
    html_body = re.sub(r'<pre>.*?</pre>', replace_pre_newlines, html_body, flags=re.DOTALL)
    
    # Strip language classes from <code> tags to prevent Google Docs from rendering prefix labels (e.g. 'bash')
    html_body = re.sub(r'<code class="language-[^"]+">', '<code>', html_body)
    
    # Wrap in HTML template
    html_document = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body {{
    font-family: Arial, sans-serif;
    line-height: 1.5;
    color: #333333;
  }}
  h1 {{
    color: #0f4c81;
    border-bottom: 1px solid #cccccc;
    padding-bottom: 5px;
    margin-top: 30px;
  }}
  h2 {{
    color: #1e293b;
    margin-top: 25px;
  }}
  h3 {{
    color: #475569;
  }}
  table {{
    border-collapse: collapse;
    width: 100%;
    margin: 20px 0;
  }}
  th, td {{
    border: 1px solid #dddddd;
    text-align: left;
    padding: 8px;
  }}
  th {{
    background-color: #f2f2f2;
  }}
  code {{
    background-color: #f1f5f9;
    padding: 2px 4px;
    font-family: monospace;
    font-size: 0.9em;
  }}
  pre {{
    background-color: #f1f5f9;
    padding: 10px;
    border: 1px solid #e2e8f0;
    overflow-x: auto;
  }}
  pre code {{
    background-color: transparent;
    padding: 0;
  }}
  hr {{
    border: 0;
    border-top: 2px solid #0f4c81;
    margin: 40px 0;
  }}
</style>
</head>
<body>
{html_body}
</body>
</html>
"""
    return html_document

def authenticate_google_drive():
    try:
        from google.oauth2 import service_account
        from google.auth.transport.requests import Request
        from google.oauth2.credentials import Credentials
        from google_auth_oauthlib.flow import InstalledAppFlow
        from googleapiclient.discovery import build
    except ImportError:
        print("[INFO] Google client libraries not installed. Installing them now...")
        import subprocess
        subprocess.check_call([
            sys.executable, "-m", "pip", "install", 
            "google-api-python-client", "google-auth-httplib2", "google-auth-oauthlib"
        ])
        from google.oauth2 import service_account
        from google.auth.transport.requests import Request
        from google.oauth2.credentials import Credentials
        from google_auth_oauthlib.flow import InstalledAppFlow
        from googleapiclient.discovery import build

    # Drive file scope
    SCOPES = ['https://www.googleapis.com/auth/drive']
    
    # Method 1: gcloud Application Default Credentials (ADC)
    gcloud_adc_path = (Path.home() / ".config/gcloud/application_default_credentials.json")
    if gcloud_adc_path.exists():
        try:
            print("[INFO] Authenticating using gcloud Application Default Credentials...")
            os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(gcloud_adc_path)
            import google.auth
            creds, project = google.auth.default(scopes=SCOPES)
            service = build('drive', 'v3', credentials=creds)
            # Make a simple test call to ensure credentials are valid and authorized
            service.files().list(pageSize=1).execute()
            print("[SUCCESS] Successfully authenticated with gcloud credentials!")
            return service, False  # Already user's account, no separate sharing step needed
        except Exception as e:
            print(f"[INFO] gcloud ADC authentication failed or unauthorized: {e}")
            print("[INFO] Falling back to other authentication methods...")
            
    # Method 2: Service Account
    if SERVICE_ACCOUNT_FILE.exists():
        print("[INFO] Authenticating using Service Account credentials...")
        creds = service_account.Credentials.from_service_account_file(
            str(SERVICE_ACCOUNT_FILE), scopes=SCOPES
        )
        return build('drive', 'v3', credentials=creds), True
        
    # Method 2: OAuth Client Flow
    if CREDENTIALS_FILE.exists() or TOKEN_FILE.exists():
        print("[INFO] Authenticating using OAuth Client flow...")
        creds = None
        if TOKEN_FILE.exists():
            creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)
            
        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                try:
                    creds.refresh(Request())
                except Exception:
                    creds = None
            
            if not creds:
                if not CREDENTIALS_FILE.exists():
                    print_instructions_and_exit()
                
                # Force opening authorization link in Google Chrome specifically on macOS
                import webbrowser
                import subprocess
                original_open = webbrowser.open
                def custom_open(url, new=0, autoraise=True):
                    try:
                        subprocess.Popen(['open', '-a', 'Google Chrome', url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                        return True
                    except Exception:
                        return original_open(url, new, autoraise)
                webbrowser.open = custom_open
                
                flow = InstalledAppFlow.from_client_secrets_file(str(CREDENTIALS_FILE), SCOPES)
                creds = flow.run_local_server(port=0)
                
            TOKEN_FILE.write_text(creds.to_json())
            
        return build('drive', 'v3', credentials=creds), False

    print_instructions_and_exit()

def main():
    ensure_venv()
    
    # Parse folder argument
    folder_id = None
    for arg in sys.argv:
        if arg.startswith("--folder="):
            folder_id = arg.split("=", 1)[1]
            break
    if not folder_id:
        if "--folder" in sys.argv:
            idx = sys.argv.index("--folder")
            if idx + 1 < len(sys.argv):
                folder_id = sys.argv[idx + 1]
        elif "-f" in sys.argv:
            idx = sys.argv.index("-f")
            if idx + 1 < len(sys.argv):
                folder_id = sys.argv[idx + 1]
                
    if folder_id and "drive.google.com" in folder_id:
        parts = folder_id.split("/folders/")
        if len(parts) > 1:
            folder_id = parts[1].split("?")[0].split("/")[0]

    # Parse document update argument
    doc_id = None
    for arg in sys.argv:
        if arg.startswith("--doc="):
            doc_id = arg.split("=", 1)[1]
            break
    if not doc_id:
        if "--doc" in sys.argv:
            idx = sys.argv.index("--doc")
            if idx + 1 < len(sys.argv):
                doc_id = sys.argv[idx + 1]
        elif "-d" in sys.argv:
            idx = sys.argv.index("-d")
            if idx + 1 < len(sys.argv):
                doc_id = sys.argv[idx + 1]
                
    if doc_id and "docs.google.com/document/d/" in doc_id:
        parts = doc_id.split("/document/d/")
        if len(parts) > 1:
            doc_id = parts[1].split("/")[0]

    # Parse source markdown argument (defaults to the slide deck for back-compat)
    source_path = SLIDES_PATH
    for arg in sys.argv:
        if arg.startswith("--source="):
            source_path = Path(arg.split("=", 1)[1]).expanduser().resolve()
            break
    else:
        if "--source" in sys.argv:
            idx = sys.argv.index("--source")
            if idx + 1 < len(sys.argv):
                source_path = Path(sys.argv[idx + 1]).expanduser().resolve()

    gcloud_adc_path = (Path.home() / ".config/gcloud/application_default_credentials.json")
    if not gcloud_adc_path.exists() and not SERVICE_ACCOUNT_FILE.exists() and not CREDENTIALS_FILE.exists() and not TOKEN_FILE.exists():
        print_instructions_and_exit()

    print("Authenticating with Google API...")
    try:
        service, is_service_account = authenticate_google_drive()
    except Exception as e:
        print(f"[ERROR] Failed to authenticate: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"Converting Markdown source to HTML: {source_path}")
    html_content = convert_md_to_html(source_path)
    
    temp_html_path = SCRIPT_DIR / "temp_presentation.html"
    temp_html_path.write_text(html_content)

    print("Uploading to Google Drive as a Google Doc...")
    try:
        from googleapiclient.http import MediaFileUpload
        
        media = MediaFileUpload(
            str(temp_html_path),
            mimetype='text/html',
            resumable=True
        )
        
        if doc_id:
            print(f"[INFO] Updating existing Google Doc: {doc_id}")
            uploaded_file = service.files().update(
                fileId=doc_id,
                media_body=media,
                fields='id,webViewLink'
            ).execute()
            file_id = uploaded_file.get('id')
            print(f"[SUCCESS] Document updated with ID: {file_id}")
        else:
            file_metadata = {
                'name': 'UCSC WordPress Block Development Presentation',
                'mimeType': 'application/vnd.google-apps.document'
            }
            if folder_id:
                file_metadata['parents'] = [folder_id]
                print(f"[INFO] Uploading directly into folder: {folder_id}")
            
            uploaded_file = service.files().create(
                body=file_metadata,
                media_body=media,
                fields='id,webViewLink'
            ).execute()
            
            file_id = uploaded_file.get('id')
            print(f"[SUCCESS] Document created with ID: {file_id}")
            
            # Share with developer email if using a Service Account and not in a shared folder
            if is_service_account:
                user_email = get_user_email()
                print(f"Sharing document with author email: {user_email}...")
                try:
                    permission = {
                        'type': 'user',
                        'role': 'writer',
                        'emailAddress': user_email
                    }
                    service.permissions().create(
                        fileId=file_id,
                        body=permission,
                        fields='id'
                    ).execute()
                    print(f"[SUCCESS] Document shared with {user_email}!")
                except Exception as share_err:
                    print(f"[WARNING] Could not share document with {user_email}: {share_err}")
                    print("Make sure your service account has permission to share externally, or manually share the file ID.")
        
        print("\n========================================================================")
        print("[SUCCESS] Published successfully to Google Docs!")
        print(f"Link to view/edit: {uploaded_file.get('webViewLink')}")
        print("========================================================================")
        
    except Exception as e:
        print(f"[ERROR] Upload failed: {e}", file=sys.stderr)
        if "storageQuotaExceeded" in str(e) and is_service_account and not folder_id:
            print("\n" + "="*72)
            print("[EXPLANATION] Storage Quota Exceeded for Service Account")
            print("="*72)
            print("Google Service Accounts start with 0 bytes of storage quota on their own Drive.")
            print("To upload files, you must upload them into a shared folder owned by a user.")
            print("\nSteps to fix:")
            print("1. Create a folder in your personal/organization Google Drive.")
            print("2. Share it with the Service Account email address:")
            print("   ucsc-wp-block-publisher@wordpress-development-498522.iam.gserviceaccount.com")
            print("   Give it 'Editor' access.")
            print("3. Copy the URL/link of that folder.")
            print("4. Re-run this script specifying that folder:")
            print("   python3 publish_to_gdoc.py --folder <FOLDER_URL_OR_ID>")
            print("="*72 + "\n")
        # Exit non-zero so callers (refresh_and_publish_*.sh) detect the failure
        # instead of reporting a false PASS.
        sys.exit(1)
    finally:
        if temp_html_path.exists():
            temp_html_path.unlink()

if __name__ == "__main__":
    main()
