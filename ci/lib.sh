#!/bin/sh

set -eu

CI_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH='' cd -- "$CI_DIR/.." && pwd)
TOOLS_DIR="$REPO_ROOT/.ci-tools/bin"
ARTIFACT_DIR=${CI_ARTIFACT_DIR:-"$REPO_ROOT/.ci-artifacts"}

export CI_DIR REPO_ROOT TOOLS_DIR ARTIFACT_DIR
export PATH="$TOOLS_DIR:$REPO_ROOT/node_modules/.bin:$PATH"

die() {
	printf 'error: %s\n' "$*" >&2
	exit 1
}

require_tool() {
	command -v "$1" >/dev/null 2>&1 || die "required tool is unavailable: $1"
}

fingerprint_file() {
	sha256sum "$1" | awk '{print $1 "  " $2}'
}

shell_files() {
	git -C "$REPO_ROOT" ls-files |
		while IFS= read -r file; do
			if [ -f "$REPO_ROOT/$file" ] &&
				head -n 1 "$REPO_ROOT/$file" |
				rg -q '^#!/(usr/)?bin/(env )?(ba|z|k)?sh([[:space:]]|$)'; then
				printf '%s\n' "$file"
			fi
		done
}

compare_debt() {
	baseline=$1
	actual=$2
	label=$3
	baseline_sorted=$(mktemp "${TMPDIR:-/tmp}/franken-baseline.XXXXXX")

	sort -u "$baseline" >"$baseline_sorted"
	sort -u "$actual" -o "$actual"
	new_debt=$(comm -13 "$baseline_sorted" "$actual")
	resolved_debt=$(comm -23 "$baseline_sorted" "$actual")
	rm -f "$baseline_sorted"

	if [ -n "$resolved_debt" ]; then
		printf '%s baseline entries no longer reproduced:\n%s\n' "$label" "$resolved_debt"
	fi

	if [ -n "$new_debt" ]; then
		printf '%s introduced unapproved debt:\n%s\n' "$label" "$new_debt" >&2
		return 1
	fi
}

text_format_files() {
	git -C "$REPO_ROOT" ls-files |
		rg '\.(md|json|ya?ml|css)$' |
		rg -v '^docs/franken-shell-pr-engineering-roadmap\.md$'
}

markdown_files() {
	git -C "$REPO_ROOT" ls-files |
		rg '\.md$' |
		rg -v '^docs/franken-shell-pr-engineering-roadmap\.md$'
}

qml_files() {
	git -C "$REPO_ROOT" ls-files 'shell/*.qml' 'shell/**/*.qml' 'shell/*.js' 'shell/**/*.js'
}

lua_files() {
	git -C "$REPO_ROOT" ls-files '*.lua' ':!references/repos/**'
}
