"""
Skills Matcher — Semantic skill similarity using SentenceTransformer.

Weight: 40% of final score (configurable).

Why semantic instead of Jaccard?
  Jaccard sees "Python" and "Django" as completely different strings → score 0.
  SentenceTransformer understands they're related → score ~0.6.

  Examples:
    "Python"           ↔ "Flask"        → ~0.65
    "JavaScript"       ↔ "React"        → ~0.55
    "Machine Learning" ↔ "TensorFlow"   → ~0.60

The model captures *meaning*, not just surface-level string overlap.
"""

from app.utils.embedding_manager import embedding_manager


def compute_skills_similarity(
    student_skills_text: str,
    internship_skills_texts: list[str],
) -> list[float]:
    """
    Batch semantic similarity between a student's skills and each
    internship's required skills.

    Args:
        student_skills_text:      Comma-joined student skills, e.g. "Python, React, MongoDB"
        internship_skills_texts:  List of comma-joined skill strings, one per internship.

    Returns:
        List of similarity scores in [0.0, 1.0], one per internship.
    """
    if not student_skills_text.strip():
        return [0.0] * len(internship_skills_texts)

    return embedding_manager.batch_similarity(
        student_skills_text, internship_skills_texts
    )
