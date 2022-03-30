
#!/bin/bash
set -euo pipefail
VERSION=v6.18.0
REPO=$(pwd)
mkdir -p workdir
cd workdir
curl -fsSLo pnpm.tar.gz https://github.com/pnpm/pnpm/archive/refs/tags/${VERSION}.tar.gz
tar --strip-component 1 -xzf pnpm.tar.gz
mkdir -p bootstrap
curl -fsSLo bootstrap/pnpm-bootstrap.js https://get.pnpm.io/v6.14.js
printf '#!/bin/sh\nnode '"$(pwd)"'/bootstrap/pnpm-bootstrap.js "$@"' > bootstrap/pnpm
chmod a+x bootstrap/pnpm
export PATH="$(pwd)/bootstrap:$PATH"
pnpm install
(
  cd packages/pnpm &&
  pnpm run compile
)
(
  cd packages/exe &&
  node_modules/.bin/pkg --target=macos-x64,macos-arm64,linuxstatic-x64 ../pnpm/dist/pnpm.cjs
)

bottle() {
  mkdir -p "$1/pnpm-exe/${VERSION#v}/bin" "$1/pnpm-exe/${VERSION#v}/.brew"
  cp "packages/exe/pnpm-$1" "$1/pnpm-exe/${VERSION#v}/bin/pnpm"
  cp "${REPO}/Formula/pnpm-exe.rb" "$1/pnpm-exe/${VERSION#v}/.brew"
  (
    cd "$1" &&
    gtar \
      --create \
      --numeric-owner \
      --format pax \
      --owner 0 \
      --group 0 \
      --sort name \
      --pax-option globexthdr.name=/GlobalHead.%n,exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
      --file "../pnpm-exe-${VERSION#v}.$2.bottle.tar.gz" \
      "pnpm-exe/${VERSION#v}"
  )
}
bottle macos-arm64 arm64_big_sur
bottle macos-x64 big_sur
bottle linuxstatic-x64 x86_64_linux
