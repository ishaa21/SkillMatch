"""
SkillMatch AI Microservice — Application Entry Point

Architecture:
  Flutter → Node.js (Express) → Python (FastAPI) → Response
                   ↕                     ↕
                MongoDB              ML Model (in-memory)

Startup sequence:
  1. Validate configuration (fail-fast on bad env vars)
  2. Load SentenceTransformer model into memory (~3s, one-time)
  3. Register middleware (logging, CORS, error handling)
  4. Register route groups (recommendations, skills, health)
  5. Start accepting requests
"""

import logging
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config.settings import settings
from app.routes import api_router
from app.utils.embedding_manager import embedding_manager
from app.middleware.request_logging import RequestLoggingMiddleware
from app.middleware.error_handler import global_exception_handler
from app.utils.logger import setup_logging

# ── Logging Setup ───────────────────────────────────────────
setup_logging()
logger = logging.getLogger(__name__)


# ── Lifespan (startup + shutdown) ───────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Startup: validate config, load ML model.
    Shutdown: log goodbye.
    """
    # ── STARTUP ────────────────────────────────────────────
    logger.info("Starting SkillMatch AI Service...")
    logger.info(f"  Environment : {settings.ENV}")
    logger.info(f"  Model       : {settings.MODEL_NAME}")
    logger.info(f"  Log level   : {settings.LOG_LEVEL}")
    logger.info(f"  Weights     : {settings.weights_dict}")

    if not settings.validate_weights():
        logger.warning(
            "Matching weights do not sum to 1.0 — "
            f"current sum is {sum(settings.weights_dict.values()):.2f}"
        )

    # Load the ML model (slow first time; cached after)
    embedding_manager.load_model()
    logger.info("AI Service is ready!")

    yield

    # ── SHUTDOWN ───────────────────────────────────────────
    logger.info("Shutting down AI Service...")


# ── Application Factory ────────────────────────────────────
app = FastAPI(
    title="SkillMatch AI Service",
    description=(
        "AI-powered internship recommendation microservice. "
        "Uses SentenceTransformer embeddings and cosine similarity "
        "for intelligent matching between students and internships."
    ),
    version="1.0.0",
    docs_url="/docs" if not settings.is_production else None,
    redoc_url="/redoc" if not settings.is_production else None,
    lifespan=lifespan,
)


# ── Middleware (order matters: last added = first executed) ──

# 1. Request logging (outermost — catches everything)
app.add_middleware(RequestLoggingMiddleware)

# 2. CORS
origins = (
    settings.ALLOWED_ORIGINS.split(",")
    if settings.ALLOWED_ORIGINS != "*"
    else ["*"]
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 3. Global catch-all error handler
app.add_exception_handler(Exception, global_exception_handler)


# ── Routes ──────────────────────────────────────────────────
app.include_router(api_router)


# ── Root ────────────────────────────────────────────────────
@app.get("/", tags=["Root"])
async def root():
    """Root endpoint — confirms the service is running."""
    return {
        "service": "SkillMatch AI Service",
        "version": "1.0.0",
        "environment": settings.ENV,
        "docs": "/docs" if not settings.is_production else "disabled",
        "health": "/health",
    }
