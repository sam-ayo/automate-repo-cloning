import subprocess
from pathlib import Path
import re
import time

import rumps
from git import Repo

APP_NAME = "CloneRepo"
ICON_FILE = None
MENU_ITEM_CLONE = "Clone Repo..."
DEFAULT_CLONE_BASE_DIR = Path.home() / "Desktop" / "playground"
IDE_APP_NAME = "Cursor"
IDE_OPEN_COMMAND_TEMPLATE = 'open -a "{app_name}" "{directory}"'

GITHUB_URL_PATTERN = re.compile(r"https?://github\.com/[^/]+/[^/\s]+")
WINDOW_TITLE = "Clone Git Repository"
WINDOW_MESSAGE = "Enter git repository URL:"
WINDOW_OK_TEXT = "Clone"
WINDOW_CANCEL_TEXT = "Cancel"
NOTIFICATION_TITLE = "Clone Success"
NOTIFICATION_MESSAGE = "Repository cloned!"
CLIPBOARD_COMMAND = ["pbpaste"]
OSASCRIPT_COMMAND_BASE = ["osascript", "-e"]

# Script to activate our app
ACTIVATE_APP_SCRIPT = '''
tell application "System Events" to set frontmost of process "Python" to true
'''

GET_ACTIVE_BROWSER_SCRIPT = '''
tell application "System Events"
    set frontApp to name of first application process whose frontmost is true
    return frontApp
end tell
'''

BROWSER_SCRIPTS = {
    "zen": '''
tell application "System Events"
  tell process "zen"
    set frontmost to true
    try
      -- Preferred path (Firefox-derived UI)
      return value of attribute "AXValue" of text field 1 of combo box 1 of toolbar "Navigation" of UI element 1 of front window
    on error
      try
        -- Fallback path: first toolbar of the window
        return value of attribute "AXValue" of text field 1 of combo box 1 of toolbar 1 of front window
      on error
        -- Last-chance: keyboard shortcut + clipboard
        keystroke "l" using {command down}
        keystroke "c" using {command down}
        key code 53
        delay 0.05
        return the clipboard
      end try
    end try
  end tell
end tell
''',
    "Google Chrome": 'tell application "Google Chrome" to get URL of active tab of front window',
    "Safari": 'tell application "Safari" to get URL of front document',
    "Arc": 'tell application "Arc" to get URL of active tab of front window',
    "Firefox": 'tell application "Firefox" to get URL of active tab of front window',
    "Brave Browser": 'tell application "Brave Browser" to get URL of active tab of front window',
    "Microsoft Edge": 'tell application "Microsoft Edge" to get URL of active tab of front window',
}


class RepoTrayApp(rumps.App):
    def __init__(self):
        super().__init__(APP_NAME, icon=ICON_FILE, menu=[MENU_ITEM_CLONE])

    @rumps.clicked(MENU_ITEM_CLONE)
    def clone_repo(self, _):
        print(f"Menu clicked - {MENU_ITEM_CLONE}", flush=True)

        detected_url = self.detect_github_url()
        if detected_url:
            print(f"Detected GitHub URL from browser: {detected_url}", flush=True)

        class TmpResponse:
            clicked = False
            text = ""
            
        # Ensure our app is at the front before showing the window
        try:
            subprocess.run(OSASCRIPT_COMMAND_BASE + [ACTIVATE_APP_SCRIPT], 
                          check=True, capture_output=True, text=True)
            # Small delay to ensure the app activation completes
            time.sleep(0.2)
        except Exception as e:
            print(f"Failed to activate app: {e}", flush=True)

        response = rumps.Window(
            title=WINDOW_TITLE,
            message=WINDOW_MESSAGE,
            default_text=detected_url or "",
            ok=WINDOW_OK_TEXT,
            cancel=WINDOW_CANCEL_TEXT,
        ).run()

        if response is None:
            print("No response from rumps.Window, using text prompt in terminal", flush=True)
            try:
                repo_url_input = input("Repository URL: ").strip()
            except EOFError:
                print("EOFError received, cannot get input.", flush=True)
                return
            if not repo_url_input:
                 print("No URL entered.", flush=True)
                 return
            response = TmpResponse()
            response.clicked = True
            response.text = repo_url_input

        if response.clicked and response.text:
            repo_url = response.text.strip()
            print(f"Cloning {repo_url}", flush=True)
            try:
                dest_dir = self.get_destination_directory(repo_url)
                Repo.clone_from(repo_url, dest_dir)
                self.open_in_ide(dest_dir)
                rumps.notification(NOTIFICATION_TITLE, NOTIFICATION_MESSAGE, dest_dir)
            except Exception as e:
                error_message = f"Error: {e}"
                try:
                    rumps.alert(error_message)
                except Exception as alert_e:
                     print(f"Failed to show rumps alert: {alert_e}", flush=True)
                print(f"Error during cloning: {e}", flush=True)

    def get_destination_directory(self, repo_url: str) -> str:
        name = repo_url.rstrip("/").split("/")[-1]
        if name.endswith(".git"):
            name = name[:-4]

        base = DEFAULT_CLONE_BASE_DIR / name
        counter = 1
        dest = base
        while dest.exists():
            dest = DEFAULT_CLONE_BASE_DIR / f"{name}-{counter}"
            counter += 1
        dest.mkdir(parents=True, exist_ok=True)
        return str(dest)

    def open_in_ide(self, directory: str):
        command = IDE_OPEN_COMMAND_TEMPLATE.format(app_name=IDE_APP_NAME, directory=directory)
        print(f"Opening directory in IDE: {command}", flush=True)
        try:
            subprocess.Popen(command, shell=True)
        except Exception as e:
            print(f"Failed to open IDE: {e}", flush=True)
            try:
                rumps.alert(f"Failed to open {IDE_APP_NAME} for {directory}:\n{e}")
            except Exception:
                pass

    def get_active_browser(self) -> str | None:
        try:
            command = OSASCRIPT_COMMAND_BASE + [GET_ACTIVE_BROWSER_SCRIPT]
            print("Detecting active browser...", flush=True)
            active_app = subprocess.check_output(command, text=True, stderr=subprocess.PIPE).strip()
            
            # Check if the active app is a browser we support
            for browser_name in BROWSER_SCRIPTS.keys():
                if browser_name in active_app:
                    print(f"Active browser detected: {browser_name}", flush=True)
                    return browser_name
            
            print(f"Active app '{active_app}' is not a supported browser", flush=True)
            return None
        except Exception as e:
            print(f"Error detecting active browser: {e}", flush=True)
            return None

    def detect_github_url(self) -> str | None:
        pattern = GITHUB_URL_PATTERN
        
        # First try to get URL from active browser
        active_browser = self.get_active_browser()
        if active_browser and active_browser in BROWSER_SCRIPTS:
            try:
                script = BROWSER_SCRIPTS[active_browser]
                command = OSASCRIPT_COMMAND_BASE + [script]
                print(f"Getting URL from active browser {active_browser}...", flush=True)
                url = subprocess.check_output(command, text=True, stderr=subprocess.PIPE).strip()
                if pattern.match(url):
                    print(f"Found URL in {active_browser}: {url}", flush=True)
                    return url
                else:
                    print(f"URL from {active_browser} ({url}) did not match pattern.", flush=True)
            except subprocess.CalledProcessError as e:
                print(f"Failed to get URL from {active_browser}: {e.stderr}", flush=True)
            except Exception as e:
                print(f"An unexpected error occurred with {active_browser}: {e}", flush=True)

        try:
            print("Trying clipboard fallback...", flush=True)
            clip = subprocess.check_output(CLIPBOARD_COMMAND, text=True, stderr=subprocess.PIPE).strip()
            if pattern.match(clip):
                print(f"Found URL in clipboard: {clip}", flush=True)
                return clip
            else:
                print(f"Clipboard content ({clip}) did not match pattern.", flush=True)
        except subprocess.CalledProcessError as e:
            print(f"Failed to get clipboard content: {e.stderr}", flush=True)
        except FileNotFoundError:
            print(f"{CLIPBOARD_COMMAND[0]} command not found. Make sure it's in the PATH.", flush=True)
        except Exception as e:
            print(f"An unexpected error occurred while checking clipboard: {e}", flush=True)

        print("No GitHub URL detected.", flush=True)
        return None


def main():
    try:
        app = RepoTrayApp()
        app.run()
    except Exception as e:
        print(f"Fatal error running RepoTrayApp: {e}", flush=True)


if __name__ == "__main__":
    main()
