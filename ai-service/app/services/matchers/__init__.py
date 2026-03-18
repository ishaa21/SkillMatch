# app/services/matchers/__init__.py
"""
Individual matching factor implementations.

Each matcher is a standalone module with a single clear responsibility:
  - skills_matcher:   Semantic skill similarity (SentenceTransformer)
  - resume_matcher:   Resume ↔ description similarity (SentenceTransformer)
  - domain_matcher:   Domain alignment (rule-based + semantic fallback)
  - location_matcher: Location proximity (rule-based)
"""

from app.services.matchers.skills_matcher import compute_skills_similarity
from app.services.matchers.resume_matcher import compute_resume_similarity
from app.services.matchers.domain_matcher import compute_domain_score
from app.services.matchers.location_matcher import compute_location_score

__all__ = [
    "compute_skills_similarity",
    "compute_resume_similarity",
    "compute_domain_score",
    "compute_location_score",
]
