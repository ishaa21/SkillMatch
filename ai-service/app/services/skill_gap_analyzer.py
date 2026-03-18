"""
Skill Gap Analyzer — Identifies skills a student is missing for an internship.

Returns actionable data like:
  "You are missing: React, Node.js, Docker"

Used by the recommendation engine to enrich each recommendation,
and can also be called independently for profile feedback.
"""


def detect_skill_gaps(
    student_skills: list[str],
    required_skills: list[str],
) -> list[str]:
    """
    Find skills the internship requires that the student does not have.

    Comparison is case-insensitive.

    Args:
        student_skills:   Student's skill name list.
        required_skills:  Internship's required skill name list.

    Returns:
        List of missing skill names (in their original casing from the
        internship data).
    """
    if not required_skills:
        return []

    student_set = {s.lower().strip() for s in student_skills}
    return [
        skill
        for skill in required_skills
        if skill.lower().strip() not in student_set
    ]
