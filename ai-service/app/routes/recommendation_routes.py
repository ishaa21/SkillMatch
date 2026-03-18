"""
Recommendation Route — POST /recommend

Called by the Node.js backend to rank internships for a student.
"""

import time
import logging
from fastapi import APIRouter, HTTPException

from app.models.schemas import RecommendRequest, RecommendResponse
from app.services.recommendation_engine import generate_recommendations

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Recommendations"])


@router.post(
    "/recommend",
    response_model=RecommendResponse,
    summary="Get AI-powered internship recommendations",
    description=(
        "Accepts a student's skills, resume text, and preferences along with "
        "a list of internships. Returns ranked recommendations with detailed "
        "score breakdowns and skill gap analysis."
    ),
)
async def recommend(request: RecommendRequest) -> RecommendResponse:
    """
    Flow:
      1. Node.js fetches student profile + active internships from MongoDB
      2. Node.js POSTs them here as JSON
      3. This service ranks internships using ML
      4. Node.js receives ranked results and returns to Flutter
    """
    start_time = time.time()

    try:
        if not request.internships:
            return RecommendResponse(
                recommendations=[],
                total=0,
                weights_used={},
            )

        result = generate_recommendations(request)

        elapsed = round(time.time() - start_time, 3)
        logger.info(
            f"Recommendations generated: {result.total} results in {elapsed}s"
        )

        return result

    except Exception as e:
        logger.error(f"Recommendation error: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate recommendations: {str(e)}",
        )
