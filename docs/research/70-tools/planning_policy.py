#!/usr/bin/env python3
"""Shared validation helpers for bounded research-planning amendments."""

from __future__ import annotations

import hashlib
from pathlib import Path


from research_paths import RESEARCH_ROOT as ROOT
DEVELOPMENT_POLICY_PATH = (
    ROOT / "60-planning/development-environment-and-deferred-qualification-policy.md"
)
HISTORICAL_ROADMAP_SHA256 = "5c09ad3dd07dc0adadc48ba67e8cdd40c823a9e73d4405808d892315f6894b9a"
AMENDED_ROADMAP_SHA256 = "a23f08ce1bf6021a6d1e9d1dd5998f85e37a7604d23bc032e0618f1c5facddb0"
DEFERRED_ROADMAP_SHA256 = "3b855d8a847104ea7f9df42159df3590a4b1fcdabf39d3eff719b20491ab8bdf"
FRAMEWORK_DEFERRAL_PATH = ROOT / "60-planning/liveview-integration-deferral.md"
FRAMEWORK_DEFERRAL_SHA256 = "3a2c3790c560191afd60f631576813760c7bbb4c05909a6f6a88058823e61e48"
HISTORICAL_ENVIRONMENT_SHA256 = "5d50cded3d70e95d47359df2a003a6979d92b8745fab012824646cc1e6bc8cfa"
AMENDED_ENVIRONMENT_SHA256 = "124b924dcd53770e55f47d07288f132acab53bed2d16007bb96edc8835c0ea9a"


def source_amendment_is_bound(path: Path, expected_sha256: str) -> bool:
    """Allow only the two exact owner-approved planning-source transitions."""
    path = Path(path)
    if not path.is_file():
        return False
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if path.as_posix().endswith("docs/research/20-notes/browser-host-implementation-milestones.md"):
        return roadmap_amendment_is_bound(expected_sha256, actual)
    if not path.as_posix().endswith("docs/research/60-planning/development-environment-and-deferred-qualification-policy.md"):
        return False
    return (expected_sha256 == HISTORICAL_ENVIRONMENT_SHA256
            and actual == AMENDED_ENVIRONMENT_SHA256
            and FRAMEWORK_DEFERRAL_PATH.is_file()
            and hashlib.sha256(FRAMEWORK_DEFERRAL_PATH.read_bytes()).hexdigest() == FRAMEWORK_DEFERRAL_SHA256)


def roadmap_amendment_error(
    expected_sha256: str,
    actual_sha256: str,
    policy_text: str | None = None,
) -> str | None:
    """Validate the exact environment amendment or its owned deferral successor."""

    if expected_sha256 != HISTORICAL_ROADMAP_SHA256 and not (
        expected_sha256 == AMENDED_ROADMAP_SHA256 and actual_sha256 == DEFERRED_ROADMAP_SHA256
    ):
        return "roadmap amendment does not start from the accepted historical source hash"
    if actual_sha256 not in {AMENDED_ROADMAP_SHA256, DEFERRED_ROADMAP_SHA256}:
        return "roadmap amendment does not match the explicitly bound amended source hash"

    if policy_text is None:
        if not DEVELOPMENT_POLICY_PATH.is_file():
            return "development-environment planning amendment is missing"
        policy_text = DEVELOPMENT_POLICY_PATH.read_text(encoding="utf-8")

    if HISTORICAL_ROADMAP_SHA256 not in policy_text:
        return "roadmap amendment omits the historical source hash"
    if AMENDED_ROADMAP_SHA256 not in policy_text:
        return "roadmap amendment omits the amended source hash"
    if "BH-22 production quality" not in policy_text:
        return "roadmap amendment omits its qualification reactivation milestone"
    if "not an open-ended stale-source exception" not in policy_text:
        return "roadmap amendment is not narrowly bounded"
    if actual_sha256 == DEFERRED_ROADMAP_SHA256:
        if not FRAMEWORK_DEFERRAL_PATH.is_file():
            return "framework deferral planning amendment is missing"
        if hashlib.sha256(FRAMEWORK_DEFERRAL_PATH.read_bytes()).hexdigest() != FRAMEWORK_DEFERRAL_SHA256:
            return "framework deferral planning amendment has an unbound change"
    return None


def roadmap_amendment_is_bound(
    expected_sha256: str,
    actual_sha256: str,
    policy_text: str | None = None,
) -> bool:
    """Return whether the exact historical-to-amended roadmap transition is bound."""

    return roadmap_amendment_error(expected_sha256, actual_sha256, policy_text) is None
