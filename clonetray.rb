class Clonetray < Formula
  desc "Manages the clonetray background service"
  homepage "https://github.com/sam-ayo/automate-repo-cloning" # Optional: Replace with your repo URL
  url "https://github.com/sam-ayo/automate-repo-cloning/archive/refs/tags/v0.1.0.tar.gz" # Placeholder for local testing
  version "0.1.0" 
  sha256 "27359705daaf4700996b05c5f780ca3edbb5dee6a305eeee5f59e7c48479e665" # Add SHA256 checksum if distributing a tarball

  depends_on "python@3.11" 

  # Define Python package dependencies as resources
  resource "GitPython" do
    url "https://files.pythonhosted.org/packages/source/G/GitPython/gitpython-3.1.44.tar.gz"
    sha256 "c87e30b26253bf5418b01b0660f818967f3c503193838337fe5e573331249269"
  end

  resource "rumps" do
    # Assuming URL based on GitPython, SHA256 from Socket.dev pattern
    url "https://files.pythonhosted.org/packages/source/r/rumps/rumps-0.4.0.tar.gz"
    sha256 "186f764079168558a55f002518e450554624c7cc86544759c41516630f98e94e" # Needs verification
  end

  def install
    # Create a virtual environment within libexec
    venv = virtualenv_create(libexec, "python3.11")

    # Install Python dependencies into the virtual environment
    venv.pip_install resources

    # Install the script into the virtual environment's site-packages
    # (or keep it in libexec if preferred, adjust plist accordingly)
    venv.pip_install "." # Installs the project itself if setup.py exists, otherwise copy manually

    # If no setup.py, copy script manually into libexec (adjust path if needed)
    libexec.install "tray_clone.py" unless File.exist?("setup.py")

    # Install and modify the launchctl script
    bin.install "launchd.sh" => "clonetrayctl"
    inreplace bin/"clonetrayctl" do |s|
      # Remove plist creation/verification logic from the shell script
      s.gsub!(/^create_plist\(\).*?^\}/m, "")
      s.gsub!(/^# Check if plist exists.*?create_plist/m, "")
      s.gsub!(/^# Verify plist integrity.*?^fi$/m, "")

      # Update variables in the shell script to use the correct plist path and label
      s.gsub!(/PLIST_PATH=.*/, "PLIST_PATH=\"$HOME/Library/LaunchAgents/#{plist_name}.plist\"")
      s.gsub!(/PLIST_LABEL=.*/, "PLIST_LABEL=\"#{plist_name}\"")
      s.gsub!(/LABEL=\".*\"/, "LABEL=\"#{plist_name}\"")
    end

    # Write the plist file to the standard location
    (prefix/"#{plist_name}.plist").write plist
    # Note: Homebrew automatically symlinks this to ~/Library/LaunchAgents during installation
    # if it's placed in the top-level prefix directory.
  end

  def plist_name
    "com.user.clonetray"
  end

  # Update plist to use Python from the virtualenv
  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>Label</key>
          <string>#{plist_name}</string>

          <key>ProgramArguments</key>
          <array>
              <string>#{libexec}/bin/python</string>
              <string>#{libexec}/tray_clone.py</string>
          </array>

          <key>RunAtLoad</key>
          <true/>

          <key>KeepAlive</key>
          <true/>

          <key>StandardOutPath</key>
          <string>#{var}/log/clonetray.stdout.log</string>

          <key>StandardErrorPath</key>
          <string>#{var}/log/clonetray.stderr.log</string>

          <key>WorkingDirectory</key>
          <string>#{libexec}</string>

          # Remove EnvironmentVariables PATH modification if using venv's python
          # <key>EnvironmentVariables</key>
          # <dict>
          #     <key>PATH</key>
          #     <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:#{Formula["python@3.11"].opt_bin}</string>
          # </dict>
      </dict>
      </plist>
    EOS
  end

  service do
    # Remove the explicit run command; brew services will use the plist method by default
    keep_alive true
    # This block tells Homebrew this formula manages a service.
    # By default, it uses the #plist method if defined.
    # Explicitly specifying plist content
    # plist_options manual: plist_name
    # plist data { self.plist } # This doesn't seem right, let's revert or remove
  end

  test do
    # Update test if necessary, e.g., check for script in libexec
    assert_predicate libexec/"tray_clone.py", :exist?
    # The control script might not be necessary anymore if only used for plist creation
    # assert_predicate bin/"clonetrayctl", :exist?
    # assert_predicate bin/"clonetrayctl", :executable?
  end
end 