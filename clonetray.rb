class Clonetray < Formula
  desc "Manages the clonetray background service"
  homepage "https://github.com/sam-ayo/automate-repo-cloning" # Optional: Replace with your repo URL
  url "https://github.com/sam-ayo/automate-repo-cloning/archive/refs/tags/v0.1.0.tar.gz" # Placeholder for local testing
  version "0.1.0" 
  sha256 "27359705daaf4700996b05c5f780ca3edbb5dee6a305eeee5f59e7c48479e665" # Add SHA256 checksum if distributing a tarball

  depends_on "python@3.11" 

  def install
    libexec.install "tray_clone.py"

    # bin.install "launchd.sh" => "clonetrayctl"

    # inreplace bin/"clonetrayctl" do |s|
    #   s.gsub!(/^create_plist\(\) \{.*?^\}/m, "")
    #   s.gsub!(/^# Check if plist exists.*create_plist/m, "")
    #   s.gsub!(/^# Verify plist integrity.*?^fi$/m, "")

    #   s.gsub!(/PLIST_PATH=.*/, "PLIST_PATH=\"$HOME/Library/LaunchAgents/#{plist_name}.plist\"") # This line would fail anyway
    #   s.gsub!(/PLIST_LABEL=.*/, "PLIST_LABEL=\"#{plist_name}\"") # This line would fail anyway
    #   s.gsub!(/LABEL=\".*\"/, "LABEL=\"#{plist_name}\"") # This line would fail anyway
    # end

    # (prefix/"#{plist_name}.plist").write plist # Remove this line
  end

  service do
    run [Formula["python@3.11"].opt_bin/"python3", opt_libexec/"tray_clone.py"]
    keep_alive true
    run_at_load true
    working_dir opt_libexec
    log_path var/"log/clonetray.log"
    error_log_path var/"log/clonetray.log"
    environment_variables PATH: "#{std_service_path_env}:#{Formula["python@3.11"].opt_bin}"
  end

  # test do
  #   assert_predicate bin/"clonetrayctl", :exist? # Remove test for clonetrayctl
  #   assert_predicate bin/"clonetrayctl", :executable? # Remove test for clonetrayctl
  # end
end 