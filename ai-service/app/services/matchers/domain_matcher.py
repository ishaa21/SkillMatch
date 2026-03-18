"""
Domain Matcher — Checks alignment between student preference and internship domain.

Weight: 15% of final score (configurable).

Uses a tiered scoring strategy:
  1.0  — Exact domain match in the internship's domain list
  0.8  — Domain keyword found in internship title
  0.7  — Partial substring overlap (e.g. "web" in "web development")
  0.5  — High semantic similarity (cosine > 0.6)
  0.3  — Moderate semantic similarity OR no student preference
  0.1  — No match at all
"""

from app.models.schemas import InternshipInput
from app.utils.embedding_manager import embedding_manager


def compute_domain_score(
    preferred_domain: str,
    internship: InternshipInput,
) -> float:
    """
    Score how well an internship's domain aligns with the student's
    preferred domain.

    Args:
        preferred_domain:  Student's preferred domain string.
        internship:        Internship Pydantic model.

    Returns:
        Score in [0.0, 1.0].
    """
    # No preference → mild positive so we don't penalize undecided students
    if not preferred_domain.strip():
        return 0.3

    domain_lower = preferred_domain.lower().strip()
    internship_domains_lower = [d.lower() for d in internship.domains]

    # ── Tier 1: Exact match in domain list ──────────────────
    if domain_lower in internship_domains_lower:
        return 1.0

    # ── Tier 2: Keyword in title ────────────────────────────
    if domain_lower in internship.title.lower():
        return 0.8

    # ── Tier 3: Partial substring overlap ───────────────────
    for d in internship_domains_lower:
        if domain_lower in d or d in domain_lower:
            return 0.7

    # ── Tier 4: Semantic similarity fallback ────────────────
    if internship.domains:
        domains_text = ", ".join(internship.domains)
        sim = embedding_manager.similarity(preferred_domain, domains_text)
        if sim > 0.6:
            return 0.5
        if sim > 0.4:
            return 0.3

    return 0.1
