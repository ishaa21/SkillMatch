"""
Skill Extractor — Extracts technical skills from resume text.

Uses keyword matching against the skill database (skill_database.py).
No ML model required — fast and deterministic.

Strategy:
  1. Lowercase the resume text.
  2. Scan for each known skill, longest-first (greedy matching).
  3. Use word boundaries to avoid false positives ("react" inside "reactionary").
  4. Normalize aliases to canonical forms ("reactjs" → "react").
  5. Return a sorted, deduplicated list.
"""

import re
import logging
from functools import lru_cache

from app.utils.skill_database import SORTED_SKILLS, ALIAS_MAP

logger = logging.getLogger(__name__)

# Characters that break \b regex word-boundary assertions
_SPECIAL_CHARS = frozenset(["+", "#", "."])


@lru_cache(maxsize=1024)
def extract_skills(resume_text: str) -> list[str]:
    """
    Extract technical skills from resume text.

    Args:
        resume_text: Plain text of the resume.

    Returns:
        Sorted list of unique, canonical skill names found in the text.
    """
    if not resume_text or not resume_text.strip():
        return []

    text_lower = resume_text.lower()
    found: set[str] = set()

    for skill in SORTED_SKILLS:
        if _match_skill(skill, text_lower):
            found.add(skill)

    normalized = _deduplicate_aliases(found)
    return sorted(normalized)


def _match_skill(skill: str, text: str) -> bool:
    """
    Check whether a skill appears in lowercased text.

    Uses word-boundary regex for normal skills.
    Falls back to substring check for skills containing +, #, or .
    because \\b doesn't work correctly around those characters.
    """
    if any(ch in skill for ch in _SPECIAL_CHARS):
        return skill in text

    pattern = r"\b" + re.escape(skill) + r"\b"
    return bool(re.search(pattern, text))


def _deduplicate_aliases(skills: set[str]) -> set[str]:
    """
    Map variant names to canonical forms.

    e.g. {"react", "reactjs", "react.js"} → {"react"}
    """
    return {ALIAS_MAP.get(s, s) for s in skills}
