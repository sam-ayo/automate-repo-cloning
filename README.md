# CloneTray

CloneTray is a macOS menu bar application that provides a quick way to clone Git repositories. It attempts to automatically detect a GitHub URL from your active web browser or clipboard, prompts for confirmation, clones the repository into `~/Desktop/playground/` (avoiding name collisions), and then opens the cloned directory in the Cursor IDE.

## Installation (via Homebrew)

1. **Tap the Repository:**
    Add the custom Homebrew tap which contains the CloneTray formula:

    ```bash
    brew tap sam-ayo/clonetray
    ```

2. **Install CloneTray:**
    Install the tool using Homebrew:

    ```bash
    brew install clonetray
    ```

    This will install the necessary scripts and dependencies.

## Usage

CloneTray runs as a background service managed by `launchd` via Homebrew services.

* **Start the Service:**

    ```bash
    brew services start clonetray
    ```

    This will start the service immediately and configure it to launch automatically on login.

* **Stop the Service:**

    ```bash
    brew services stop clonetray
    ```

    This will stop the service and prevent it from launching automatically on login.

* **Restart the Service:**

    ```bash
    brew services restart clonetray
    ```

* **Check Service Status:**

    ```bash
    brew services list
    ```

    Look for `clonetray` in the list to see if it's `started` or `stopped`.

* **Check Logs:**
    Logs are stored in the standard Homebrew log directory:
  * Standard Output: `/opt/homebrew/var/log/clonetray.stdout.log`
  * Standard Error: `/opt/homebrew/var/log/clonetray.stderr.log`

## Contributing

Feel free to create a PR to contribute.
