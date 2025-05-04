class Clonetray < Formula
  desc "Manages the clonetray background service"
  homepage "https://github.com/sam-ayo/automate-repo-cloning" # Optional: Replace with your repo URL
  url "https://github.com/sam-ayo/automate-repo-cloning/archive/refs/tags/v0.1.0.tar.gz" # Placeholder for local testing
  version "0.1.0" 
  sha256 "27359705daaf4700996b05c5f780ca3edbb5dee6a305eeee5f59e7c48479e665" # Add SHA256 checksum if distributing a tarball

  depends_on "python@3.11" 

  def install
    libexec.install "tray_clone.py"

    bin.install "launchd.sh" => "clonetrayctl"

    inreplace bin/"clonetrayctl" do |s|
      s.gsub!(/^create_plist\(\) \{.*?^\}/m, "")
      s.gsub!(/^# Check if plist exists.*create_plist/m, "")
      s.gsub!(/^# Verify plist integrity.*?^fi$/m, "")

      s.gsub!(/PLIST_PATH=.*/, "PLIST_PATH=\"$HOME/Library/LaunchAgents/#{plist_name}.plist\"")
      s.gsub!(/PLIST_LABEL=.*/, "PLIST_LABEL=\"#{plist_name}\"")
      s.gsub!(/LABEL=\".*\"/, "LABEL=\"#{plist_name}\"")
    end

    (prefix/"#{plist_name}.plist").write plist
  end

  def plist_name
    "com.user.clonetray"
  end

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
              <string>#{Formula["python@3.11"].opt_bin}/python3</string>
              <string>#{opt_libexec}/tray_clone.py</string>
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
          <string>#{opt_libexec}</string>

          <key>EnvironmentVariables</key>
          <dict>
              <key>PATH</key>
              <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:#{Formula["python@3.11"].opt_bin}</string>
          </dict>
      </dict>
      </plist>
    EOS
  end

  test do
    assert_predicate bin/"clonetrayctl", :exist?
    assert_predicate bin/"clonetrayctl", :executable?
  end
end 