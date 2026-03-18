"""
Resume Matcher — Semantic similarity between resume text and internship descriptions.

Weight: 30% of final score (configurable).

This catches context that skill matching alone misses:
  "Built a full-stack e-commerce platform" matches
  "Looking for full-stack developer" even without
  explicit skill overlap.

The full resume text is encoded as a single embedding and compared
against each internship description in one vectorized batch.
"""

from app.utils.embedding_manager import embedding_manager


def compute_resume_similarity(
    resume_text: str,
    internship_descriptions: list[str],
) -> list[float]:
    """
    Batch semantic similarity between a student's resume and
    each internship's description.

    Args:
        resume_text:               Plain text of the student's resume / bio.
        internship_descriptions:   List of internship description strings.

    Returns:
        List of similarity scores in [0.0, 1.0], one per internship.
    """
    if not resume_text.strip():
        return [0.0] * len(internship_descriptions)

    return embedding_manager.batch_similarity(
        resume_text, internship_descriptions
    )
