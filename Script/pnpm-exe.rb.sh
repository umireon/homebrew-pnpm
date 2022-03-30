#!/bin/bash
VERSION="$1"

set -euo pipefail

URL="https://github.com/pnpm/pnpm/archive/refs/tags/${VERSION}.tar.gz"
curl -fsSLo pnpm.tar.gz "${URL}"
SHA256SUM=$(sha256sum pnpm.tar.gz | cut -d' ' -f1)
cat >Formula/pnpm-exe.rb <<EOS
class PnpmExe < Formula
  desc "📦🚀 Fast, disk space efficient package manager"
  homepage "https://pnpm.io/"
  url "${URL}"
  sha256 "${SHA256SUM}"
  license "MIT"

  depends_on "node" => :build

  # Described in https://github.com/pnpm/pnpm#installation
  # Managed by https://github.com/pnpm/get
  resource "pnpm-bootstrap" do
    url "https://get.pnpm.io/v6.14.js"
    sha256 "c80817f1dac65ee497fc8ca0b533e497aacfbf951a917ff4652825710bbacda7"
  end

  def install
    (prefix/"etc").mkpath
    (prefix/"etc/npmrc").atomic_write "global-bin-dir = \${HOME}/Library/pnpm\n" if OS.mac?
    (prefix/"etc/npmrc").atomic_write "global-bin-dir = \${HOME}/.local/pnpm\n" if OS.linux?

    bootstrap_bin = buildpath/"bootstrap"
    resource("pnpm-bootstrap").stage do |r|
      bootstrap_bin.install "v#{r.version}.js"
      (bootstrap_bin/"pnpm").write_env_script Formula["node"].bin/"node", buildpath/"bootstrap/v#{r.version}.js", {}
      chmod 0755, bootstrap_bin/"pnpm"
    end
    ENV.prepend_path "PATH", bootstrap_bin
    system "pnpm", "install"
    cd "packages/pnpm" do
      system "pnpm", "run", "compile"
    end
    cd "packages/exe" do
      system "node_modules/.bin/pkg", "--target=host", "../pnpm/dist/pnpm.cjs"
      bin.install "pnpm"
    end
  end

  def caveats
    pnpm_path = nil
    on_macos do
      pnpm_path = "\$HOME/Library/pnpm"
    end
    on_linux do
      pnpm_path = "\$HOME/.local/pnpm"
    end
    <<~EOS if pnpm_path
      Add the following to #{shell_profile} or your desired shell
      configuration file if you would like global packages in PATH:

        export PATH="#{pnpm_path}:\$PATH"
    EOS
  end

  test do
    ENV.prepend_path "PATH", testpath/"Library/pnpm" if OS.mac?
    ENV.prepend_path "PATH", testpath/".local/pnpm" if OS.linux?
    system "#{bin}/pnpm", "env", "use", "--global", "16"
    system "#{bin}/pnpm", "install", "--global", "npm"
    system "#{bin}/pnpm", "init", "-y"
    assert_predicate testpath/"package.json", :exist?, "package.json must exist"
  end
end
EOS
cp Formula/pnpm-exe.rb "$(brew --repo umireon/pnpm)/Formula"
