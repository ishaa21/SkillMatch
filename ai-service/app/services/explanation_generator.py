"""
Explanation Generator — Creates human-readable explanations for recommendations.

Takes the raw score breakdown and skill gaps and formats them into
a simple, user-friendly string that can be displayed in the UI.
"""

from app.models.schemas import ScoreBreakdown


def generate_explanation(
    breakdown: ScoreBreakdown,
    weights: dict[str, float],
    skill_gaps: list[str]
) -> str:
    """
    Generate a 1-2 sentence explanation of why an internship was recommended.

    Args:
        breakdown: The calculated score breakdown.
        weights: The weights dictionary used for the scores.
        skill_gaps: List of missing skills.

    Returns:
        A human-readable explanation string.
    """
    reasons = []

    # Calculate max possible scores per factor
    max_skills = weights["skills"] * 100
    max_resume = weights["resume"] * 100
    max_domain = weights["domain"] * 100
    max_location = weights["location"] * 100

    # Identify strong factors (>80% of their potential)
    if max_skills > 0 and breakdown.skills >= max_skills * 0.8:
        reasons.append("a strong match with your technical skills")

    if max_resume > 0 and breakdown.resume >= max_resume * 0.8:
        reasons.append("great alignment with your resume experience")

    if max_domain > 0 and breakdown.domain >= max_domain * 0.8:
        reasons.append("perfect domain alignment")

    if max_location > 0 and breakdown.location >= max_location * 0.8:
        reasons.append("an ideal location fit")

    # Construct the base explanation
    if not reasons:
        explanation = "Recommended as a general fit for your profile."
    else:
        if len(reasons) == 1:
            explanation = f"Recommended for {reasons[0]}."
        elif len(reasons) == 2:
            explanation = f"Recommended for {reasons[0]} and {reasons[1]}."
        else:
            explanation = f"Recommended for {reasons[0]}, {reasons[1]}, and {reasons[2]}."

    # Append actionable feedback based on skill gaps
    if skill_gaps:
        if len(skill_gaps) == 1:
            gaps_str = skill_gaps[0]
        elif len(skill_gaps) == 2:
            gaps_str = f"{skill_gaps[0]} and {skill_gaps[1]}"
        else:
            gaps_str = f"{skill_gaps[0]}, {skill_gaps[1]}, and {len(skill_gaps)-2} others"
            
        explanation += f" You may need to review {gaps_str}."

    return explanation
