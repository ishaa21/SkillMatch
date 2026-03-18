"""
Location Matcher — Rule-based location proximity scoring.

Weight: 15% of final score (configurable).

Scoring tiers:
  1.0  — Internship is Remote (matches everyone)
  1.0  — Exact city / substring match
  0.7  — Word-level overlap (e.g. "Bangalore" in "Bangalore, India")
  0.3  — Student has no location preference (don't penalize)
  0.1  — Complete mismatch
"""

from app.models.schemas import InternshipInput


def compute_location_score(
    preferred_location: str,
    internship: InternshipInput,
) -> float:
    """
    Score how well an internship's location matches the student's
    preferred location.

    Args:
        preferred_location:  Student's preferred city/region.
        internship:          Internship Pydantic model.

    Returns:
        Score in [0.0, 1.0].
    """
    # ── Remote = universal match ────────────────────────────
    if internship.work_mode.lower() == "remote":
        return 1.0

    # ── No preference → mild positive ───────────────────────
    if not preferred_location.strip():
        return 0.3

    pref_lower = preferred_location.lower().strip()
    intern_location_lower = internship.location.lower().strip()

    # ── Exact or substring match ────────────────────────────
    if pref_lower in intern_location_lower or intern_location_lower in pref_lower:
        return 1.0

    # ── Word-level overlap ──────────────────────────────────
    pref_words = set(pref_lower.split())
    location_words = set(intern_location_lower.split())
    if pref_words & location_words:
        return 0.7

    return 0.1
