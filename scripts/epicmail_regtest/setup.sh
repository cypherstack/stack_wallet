#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"
work="${EPICMAIL_REGTEST_WORK:-$repo_root/.epicmail-regtest}"
src="$work/src"

epic_commit=c7e3fe09d823849a03dbe175f72736a2fab486c1
wallet_commit=3df6316a08da8350f784f27f2efcc0a68628e2c9
epicmail_commit=fe3249790acade16302d2ad807dbc02e70ff4886
legacy_commit=774855da54b1bd56e0c4c9c05e5e1ad76ce4f935
patch_file="$script_dir/patches/epic-usernet-test-miner.patch"

for command in git cargo npm node python3 curl; do
  command -v "$command" >/dev/null || {
    printf 'Missing required command: %s\n' "$command" >&2
    exit 2
  }
done
node_major="$(node -p 'Number(process.versions.node.split(".")[0])')"
if ! [[ "$node_major" =~ ^[0-9]+$ ]] || ((node_major < 20)); then
  printf 'Node.js 20 or newer is required; found %s.\n' "$(node --version)" >&2
  exit 2
fi
mkdir -p "$src"

checkout() {
  local name="$1" url="$2" commit="$3" dir="$src/$1"
  if [[ -L "$dir" ]]; then
    printf 'Refusing symlinked source directory: %s\n' "$dir" >&2
    exit 1
  fi
  if [[ ! -e "$dir" ]]; then
    git clone --filter=blob:none "$url" "$dir"
  elif [[ ! -d "$dir/.git" ]]; then
    printf 'Existing source is not an owned Git clone: %s\n' "$dir" >&2
    exit 1
  fi
  if [[ "$(git -C "$dir" remote get-url origin)" != "$url" ]]; then
    printf 'Unexpected origin for %s; refusing to mutate it.\n' "$dir" >&2
    exit 1
  fi
  if [[ "$name" == epic ]] &&
    git -C "$dir" apply --unidiff-zero --reverse --check \
      "$patch_file" 2>/dev/null; then
    git -C "$dir" apply --unidiff-zero --reverse "$patch_file"
  fi
  if [[ -n "$(git -C "$dir" status --porcelain=v1)" ]]; then
    printf 'Source clone has unrelated changes; refusing to mutate %s.\n' "$dir" >&2
    exit 1
  fi
  git -C "$dir" fetch origin "$commit"
  git -C "$dir" checkout --detach "$commit"
  [[ "$(git -C "$dir" rev-parse HEAD)" == "$commit" ]]
  printf '%-18s %s\n' "$name" "$commit"
}

checkout epic https://github.com/EpicCash/epic.git "$epic_commit"
checkout epic-wallet https://github.com/cypherstack/epic-wallet.git "$wallet_commit"
checkout epicmail https://github.com/BTLabsUK/epicmail.git "$epicmail_commit"
checkout epicboxnodejs https://github.com/who-biz/epicboxnodejs.git "$legacy_commit"

if ! git -C "$src/epic" apply --unidiff-zero --check \
  "$patch_file" 2>/dev/null; then
  printf 'Epic miner patch does not apply cleanly. Remove %s and retry.\n' "$src/epic" >&2
  exit 1
fi
git -C "$src/epic" apply --unidiff-zero "$patch_file"
if ! diff -q "$patch_file" \
  <(git -C "$src/epic" diff --no-ext-diff --unified=0) >/dev/null; then
  printf 'Epic clone differs from the single expected test patch.\n' >&2
  exit 1
fi

(cd "$src/epic" && cargo build --release --locked)
(cd "$src/epic-wallet" && cargo build --release --locked)
(cd "$src/epicmail" && cargo build --release --locked)
(cd "$src/epicmail" && cargo test --locked)

git -C "$src/epicboxnodejs" submodule update --init --recursive
(cd "$src/epicboxnodejs" && npm ci)
(cd "$src/epicboxnodejs/epicboxlib_source" && cargo build --release --locked)

printf '\nPinned Epic/Epicmail regtest tools are ready under %s.\n' "$work"
