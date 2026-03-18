"""
Recommendation Engine — Orchestrates all matching factors.

This file is the *coordinator*. It does NOT contain matching logic itself.
Each factor lives in its own module under services/matchers/.

Pipeline:
  1. Prepare texts from the request
  2. Delegate to each matcher (skills, resume, domain, location)
  3. Combine scores using configurable weights
  4. Detect skill gaps
  5. Sort, filter, and return
"""

import logging

from app.config.settings import settings
from app.models.schemas import (
    RecommendRequest,
    RecommendationItem,
    RecommendResponse,
    ScoreBreakdown,
)
from app.services.matchers import (
    compute_skills_similarity,
    compute_resume_similarity,
    compute_domain_score,
    compute_location_score,
)
from app.services.skill_gap_analyzer import detect_skill_gaps

logger = logging.getLogger(__name__)


def generate_recommendations(request: RecommendRequest) -> RecommendResponse:
    """
    Main entry point — ranks internships for a student.

    Called by the /recommend route handler.
    """
    internships = request.internships
    weights = settings.weights_dict

    if not internships:
        return _empty_response(weights)

    # ── 1. Prepare input texts ──────────────────────────────
    student_skills_text = ", ".join(request.student_skills) if request.student_skills else ""
    resume_text = request.resume_text or ""
    preferred_domain = request.preferred_domain or ""
    preferred_location = request.preferred_location or ""

    internship_skills_texts = [
        ", ".join(i.required_skills) if i.required_skills else i.title
        for i in internships
    ]
    internship_descriptions = [
        i.description if i.description else i.title
        for i in internships
    ]

    # ── 2. Compute each factor (batch where possible) ───────
    skills_scores = compute_skills_similarity(student_skills_text, internship_skills_texts)
    resume_scores = compute_resume_similarity(resume_text, internship_descriptions)
    domain_scores = [compute_domain_score(preferred_domain, i) for i in internships]
    location_scores = [compute_location_score(preferred_location, i) for i in internships]

    # ── 3. Combine into final scored recommendations ────────
    recommendations = _build_recommendations(
        internships=internships,
        skills_scores=skills_scores,
        resume_scores=resume_scores,
        domain_scores=domain_scores,
        location_scores=location_scores,
        weights=weights,
        student_skills=request.student_skills,
    )

    # ── 4. Sort, filter, limit ──────────────────────────────
    recommendations.sort(key=lambda r: r.score, reverse=True)
    recommendations = [r for r in recommendations if r.score >= settings.MIN_SCORE_THRESHOLD]
    recommendations = recommendations[: settings.MAX_RECOMMENDATIONS]

    logger.info(f"Ranked {len(recommendations)} internships (from {len(internships)} candidates)")

    return RecommendResponse(
        recommendations=recommendations,
        total=len(recommendations),
        weights_used=weights,
    )


# ─── Internal helpers ───────────────────────────────────────


def _build_recommendations(
    *,
    internships: list,
    skills_scores: list[float],
    resume_scores: list[float],
    domain_scores: list[float],
    location_scores: list[float],
    weights: dict[str, float],
    student_skills: list[str],
) -> list[RecommendationItem]:
    """Combine raw factor scores into RecommendationItem objects."""
    from app.services.explanation_generator import generate_explanation

    results: list[RecommendationItem] = []

    for i, internship in enumerate(internships):
        # Weighted contributions (each: raw_0-1 × weight × 100)
        w_skills = skills_scores[i] * weights["skills"] * 100
        w_resume = resume_scores[i] * weights["resume"] * 100
        w_domain = domain_scores[i] * weights["domain"] * 100
        w_location = location_scores[i] * weights["location"] * 100

        total = max(0.0, min(100.0, w_skills + w_resume + w_domain + w_location))
        
        breakdown = ScoreBreakdown(
            skills=round(w_skills, 1),
            resume=round(w_resume, 1),
            domain=round(w_domain, 1),
            location=round(w_location, 1),
        )
        
        skill_gaps = detect_skill_gaps(student_skills, internship.required_skills)
        explanation = generate_explanation(breakdown, weights, skill_gaps)

        results.append(
            RecommendationItem(
                id=internship.id,
                title=internship.title,
                company_name=internship.company_name,
                score=round(total),
                breakdown=breakdown,
                explanation=explanation,
                skill_gaps=skill_gaps,
            )
        )

    return results


def _empty_response(weights: dict[str, float]) -> RecommendResponse:
    return RecommendResponse(recommendations=[], total=0, weights_used=weights)
