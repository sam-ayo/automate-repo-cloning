# CloneTray

A macOS menu bar application that automatically clones Git repositories.

## Installation

1. Clone the repo
2. Open Terminal and navigate to the extracted directory
3. Make the launch script executable:

   ```bash
   chmod +x launchd.sh
   ```

4. To start the application:

   ```bash
   ./launchd.sh start
   ```

5. To stop the application:

   ```bash
   ./launchd.sh stop
   ```

## Configuration

CloneTray can be configured via the `config.yml` file:

```yaml
default_clone_base_dir: ~/Developer
ide_app_name: Cursor
```

Modify these values according to your preferences before starting the application.
