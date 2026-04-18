class RecallBridge < Formula
  desc "Chrome native messaging host for the Recall extension"
  homepage "https://github.com/ty-asuralo/recall-bridge"
  url "https://github.com/ty-asuralo/recall-bridge/archive/refs/tags/v0.1.3.tar.gz"
  sha256 "d60e162458aed668a5704e373fee33abee7adba9b08c1066f3c1ef831f0a0817"
  license "MIT"

  depends_on "node@20"

  def install
    system "npm", "install", "--ignore-scripts"
    system "npm", "run", "build"

    libexec.install "dist", "package.json", "node_modules"

    (bin/"recall-bridge").write <<~SH
      #!/bin/bash
      # Chrome doesn't inherit the user's shell PATH
      for d in "$HOME/.local/bin" "$HOME/.bun/bin" "/opt/homebrew/bin" "/usr/local/bin"; do
        [[ -d "$d" ]] && export PATH="$d:$PATH"
      done
      for d in "$HOME"/Library/Python/*/bin; do
        [[ -d "$d" ]] && export PATH="$d:$PATH"
      done
      exec "#{Formula["node@20"].opt_bin}/node" "#{libexec}/dist/index.js" "$@"
    SH

    # Write native messaging host manifest
    manifest = {
      name: "com.recall.bridge",
      description: "Recall memory bridge",
      path: "#{bin}/recall-bridge",
      type: "stdio",
      allowed_origins: ["chrome-extension://PLACEHOLDER_EXTENSION_ID/"],
    }
    (buildpath/"com.recall.bridge.json").write JSON.pretty_generate(manifest)
    (share/"recall-bridge").install "com.recall.bridge.json"
  end

  def post_install
    native_hosts = Dir.home + "/Library/Application Support/Google/Chrome/NativeMessagingHosts"
    mkdir_p native_hosts
    ln_sf share/"recall-bridge/com.recall.bridge.json", native_hosts/"com.recall.bridge.json"
  end

  def caveats
    <<~EOS
      Run the interactive setup:

        recall-bridge setup

      It will ask for your Recall extension ID (from chrome://extensions),
      backend choice, and export folder — then configure everything.

      After setup, reload the Recall extension in chrome://extensions.
    EOS
  end

  test do
    output = pipe_output(bin/"recall-bridge", "", 0)
    assert_match "recall-bridge", output || ""
  end
end
