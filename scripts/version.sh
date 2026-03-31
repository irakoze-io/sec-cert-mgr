#!/usr/bin/env sh

increment_gradle_version() {
    # gradle_file="${1:-build.gradle}"
    # Read gradle file from project source
    gradle_file="../build.gradle"

    if [ ! -f "$gradle_file" ]; then
        printf 'File not found: %s\n' "$gradle_file" >&2
        return 1
    fi

    current_version=$(
        sed -nE "s/^version = '([0-9]+)\.([0-9]+)\.([0-9]+)'$/\1.\2.\3/p" "$gradle_file"
    )

    if [ -z "$current_version" ]; then
        printf 'Could not find version in %s\n' "$gradle_file" >&2
        return 1
    fi

    IFS=. read -r major minor patch <<EOF
$current_version
EOF

    patch=$((patch + 1))

    if [ "$patch" -gt 99 ]; then
        patch=0
        minor=$((minor + 1))
    fi

    if [ "$minor" -gt 99 ]; then
        minor=0
        major=$((major + 1))
    fi

    next_version="${major}.${minor}.${patch}"
    tmp_file=$(mktemp)

    if ! sed "s/^version = '${current_version}'$/version = '${next_version}'/" "$gradle_file" > "$tmp_file"; then
        rm -f "$tmp_file"
        return 1
    fi

    mv "$tmp_file" "$gradle_file"
    printf '%s\n' "$next_version"
}

if [ "${0##*/}" = "version.sh" ]; then
    increment_gradle_version "$@"
fi
