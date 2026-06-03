#!/usr/bin/env python3
"""Generate docs/altstore-source.json from GitHub Releases (including pre-releases)."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone

# Fork tags:  {flavor}-v{version}-build{build}
# Upstream tags: {flavor}-v{version}-{deploymentId}
TAG_SUFFIX_RE = re.compile(
    r"-v(?P<version>[\d.]+)(?:-build(?P<build>\d+)|-(?P<suffix>[^-]+))?$",
    re.IGNORECASE,
)
IPA_NAME_RE = re.compile(r"^floaty-(?P<version>[\d.]+)-ios\.ipa$", re.IGNORECASE)

# When multiple GitHub releases share the same CFBundle version + build (e.g. CI on
# different branches), AltStore only allows one entry per (version, buildVersion).
FLAVOR_PRIORITY: dict[str, int] = {
    "release": 0,
    "beta": 1,
    "nightly": 2,
    "development": 3,
    "dev": 3,
}


def flavor_rank(flavor: str) -> int:
    key = flavor.lower()
    if key in FLAVOR_PRIORITY:
        return FLAVOR_PRIORITY[key]
    if "/" in flavor:
        return 100
    return 50


def api_get(url: str, token: str | None) -> object:
    headers = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.loads(response.read().decode())


def release_has_ios_ipa(release: dict) -> bool:
    for asset in release.get("assets") or []:
        if IPA_NAME_RE.match(asset.get("name") or ""):
            return True
    return False


def fetch_release_by_tag(repo: str, tag: str, token: str | None) -> dict | None:
    url = f"https://api.github.com/repos/{repo}/releases/tags/{tag}"
    try:
        data = api_get(url, token)
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            return None
        raise
    return data if isinstance(data, dict) else None


def wait_for_release_ipa(
    repo: str,
    tag: str,
    token: str | None,
    *,
    timeout_seconds: int = 180,
    poll_seconds: float = 5.0,
) -> None:
    """Block until GitHub's Releases API lists an iOS IPA for *tag*."""
    deadline = time.monotonic() + timeout_seconds
    attempt = 0
    while time.monotonic() < deadline:
        attempt += 1
        release = fetch_release_by_tag(repo, tag, token)
        if release and release_has_ios_ipa(release):
            print(
                f"Release {tag} has iOS IPA on API (attempt {attempt})",
                file=sys.stderr,
            )
            return
        remaining = max(0, int(deadline - time.monotonic()))
        print(
            f"Waiting for {tag} IPA on GitHub API "
            f"(attempt {attempt}, ~{remaining}s left)",
            file=sys.stderr,
        )
        time.sleep(poll_seconds)
    raise TimeoutError(
        f"Timed out after {timeout_seconds}s waiting for iOS IPA on release {tag}"
    )


def fetch_all_releases(repo: str, token: str | None) -> list[dict]:
    releases: list[dict] = []
    page = 1
    while True:
        url = (
            f"https://api.github.com/repos/{repo}/releases"
            f"?per_page=100&page={page}"
        )
        batch = api_get(url, token)
        if not isinstance(batch, list) or not batch:
            break
        releases.extend(batch)
        if len(batch) < 100:
            break
        page += 1
    return releases


def build_number_from_version(version: str) -> str:
    """Match CI --build-number when pubspec has no +build suffix."""
    return version.rsplit(".", 1)[-1]


def parse_tag(tag_name: str) -> tuple[str | None, str | None, str | None]:
    match = TAG_SUFFIX_RE.search(tag_name)
    if not match:
        return None, None, None
    version = match.group("version")
    build = match.group("build")
    if build is None:
        build = build_number_from_version(version)
    flavor = tag_name[: match.start()].strip("-") or "release"
    return flavor, version, build


def iso_date(release: dict) -> str:
    raw = release.get("published_at") or release.get("created_at")
    if not raw:
        return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return raw.replace("+00:00", "Z")


def is_preferred(candidate: dict, incumbent: dict) -> bool:
    """Prefer canonical release channels; tie-break with newer published date."""
    c_rank = flavor_rank(candidate["_flavor"])
    i_rank = flavor_rank(incumbent["_flavor"])
    if c_rank != i_rank:
        return c_rank < i_rank
    return candidate["date"] > incumbent["date"]


def build_versions(releases: list[dict]) -> list[dict]:
    best_by_version_build: dict[tuple[str, str], dict] = {}

    for release in releases:
        if release.get("draft"):
            continue

        tag = release.get("tag_name") or ""
        flavor, tag_version, tag_build = parse_tag(tag)
        body = (release.get("body") or "").strip()
        date = iso_date(release)

        for asset in release.get("assets") or []:
            name = asset.get("name") or ""
            ipa_match = IPA_NAME_RE.match(name)
            if not ipa_match:
                continue

            version = tag_version or ipa_match.group("version")
            build = tag_build or build_number_from_version(version)
            flavor_label = flavor or "unknown"
            key = (version, build)

            description = body.split("\n")[0][:500] if body else None
            if flavor_label and flavor_label != "release":
                prefix = f"[{flavor_label}] "
                description = (
                    f"{prefix}{description}"
                    if description
                    else f"{prefix}Build {build}"
                )

            entry: dict = {
                "version": version,
                "buildVersion": build,
                "marketingVersion": f"{version} ({build})",
                "date": date,
                "downloadURL": asset["browser_download_url"],
                "size": asset["size"],
                "_flavor": flavor_label,
            }
            if description:
                entry["localizedDescription"] = description

            existing = best_by_version_build.get(key)
            if existing is None or is_preferred(entry, existing):
                best_by_version_build[key] = entry

    versions: list[dict] = []
    for entry in best_by_version_build.values():
        entry.pop("_flavor", None)
        versions.append(entry)

    versions.sort(key=lambda v: v["date"], reverse=True)
    return versions


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY"))
    parser.add_argument(
        "--meta",
        default="docs/altstore-source.meta.json",
        help="Static source metadata JSON",
    )
    parser.add_argument(
        "--output",
        default="docs/altstore-source.json",
        help="Generated AltStore source path",
    )
    parser.add_argument(
        "--wait-tag",
        default=os.environ.get("ALTSTORE_WAIT_RELEASE_TAG"),
        help=(
            "After creating a release, poll until this tag's IPA appears "
            "in the GitHub API (avoids eventual-consistency races)"
        ),
    )
    parser.add_argument(
        "--wait-timeout",
        type=int,
        default=180,
        help="Seconds to wait for --wait-tag IPA (default: 180)",
    )
    args = parser.parse_args()

    if not args.repo:
        print("error: --repo or GITHUB_REPOSITORY required", file=sys.stderr)
        return 1

    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")

    with open(args.meta, encoding="utf-8") as handle:
        meta = json.load(handle)

    app_template = meta.pop("app")
    if args.wait_tag:
        try:
            wait_for_release_ipa(
                args.repo,
                args.wait_tag,
                token,
                timeout_seconds=args.wait_timeout,
            )
        except TimeoutError as exc:
            print(f"error: {exc}", file=sys.stderr)
            return 1

    try:
        releases = fetch_all_releases(args.repo, token)
    except urllib.error.HTTPError as exc:
        print(f"error: GitHub API {exc.code}: {exc.reason}", file=sys.stderr)
        return 1

    versions = build_versions(releases)
    if not versions:
        print("warning: no iOS IPA assets found in releases", file=sys.stderr)

    app = {**app_template, "versions": versions}
    source = {
        **meta,
        "apps": [app],
    }

    with open(args.output, "w", encoding="utf-8") as handle:
        json.dump(source, handle, indent=2)
        handle.write("\n")

    print(f"Wrote {args.output} with {len(versions)} version(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
