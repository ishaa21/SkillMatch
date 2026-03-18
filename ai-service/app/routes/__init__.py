"""
Route Aggregator — Collects all endpoint routers into a single router.

Import this in main.py to register all routes at once:
    from app.routes import api_router
    app.include_router(api_router)
"""

from fastapi import APIRouter

from app.routes.recommendation_routes import router as recommendation_router
from app.routes.skills_routes import router as skills_router
from app.routes.health_routes import router as health_router

api_router = APIRouter()

api_router.include_router(recommendation_router)
api_router.include_router(skills_router)
api_router.include_router(health_router)
