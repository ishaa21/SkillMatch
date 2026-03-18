"""
Health Route — GET /health

Used by:
  - Render to verify the service is alive (health check URL)
  - Node.js to check readiness before sending requests
"""

from fastapi import APIRouter
from app.models.schemas import HealthResponse
from app.utils.embedding_manager import embedding_manager

router = APIRouter(tags=["Health"])


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Service health check",
    description="Returns service status and whether the ML model is loaded.",
)
async def health_check() -> HealthResponse:
    return HealthResponse(
        status="ok",
        model_loaded=embedding_manager.is_loaded,
        version="1.0.0",
    )
