"""
Configuration — Pydantic BaseSettings for validated, typed config.

All values are read from environment variables with sensible defaults.
Pydantic validates types at construction time — a bad PORT="abc" will
crash on startup (fail-fast) instead of silently breaking later.
"""

from pydantic_settings import BaseSettings
from pydantic import field_validator


class Settings(BaseSettings):
    """
    Central configuration.

    Pydantic BaseSettings automatically reads from:
      1. Constructor kwargs
      2. Environment variables (case-insensitive)
      3. .env file
    """

    # ── Server ──────────────────────────────────────────────
    PORT: int = 8000
    HOST: str = "0.0.0.0"
    LOG_LEVEL: str = "INFO"
    ENV: str = "development"   # "development" | "production"

    # ── ML Model ────────────────────────────────────────────
    MODEL_NAME: str = "all-MiniLM-L6-v2"

    # ── Matching Weights (MUST sum to 1.0) ──────────────────
    WEIGHT_SKILLS: float = 0.40
    WEIGHT_RESUME: float = 0.30
    WEIGHT_DOMAIN: float = 0.15
    WEIGHT_LOCATION: float = 0.15

    # ── Performance ─────────────────────────────────────────
    MAX_RECOMMENDATIONS: int = 20
    MIN_SCORE_THRESHOLD: int = 10
    REQUEST_TIMEOUT_SECONDS: int = 30

    # ── CORS ────────────────────────────────────────────────
    ALLOWED_ORIGINS: str = "*"

    # ── Rate Limiting ───────────────────────────────────────
    RATE_LIMIT_PER_MINUTE: int = 60

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": False,
    }

    # ── Validators ──────────────────────────────────────────

    @field_validator("WEIGHT_SKILLS", "WEIGHT_RESUME", "WEIGHT_DOMAIN", "WEIGHT_LOCATION")
    @classmethod
    def weight_must_be_between_0_and_1(cls, v: float) -> float:
        if not 0.0 <= v <= 1.0:
            raise ValueError(f"Weight must be between 0.0 and 1.0, got {v}")
        return v

    @field_validator("LOG_LEVEL")
    @classmethod
    def log_level_must_be_valid(cls, v: str) -> str:
        valid = {"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"}
        if v.upper() not in valid:
            raise ValueError(f"LOG_LEVEL must be one of {valid}, got {v}")
        return v.upper()

    # ── Helpers ─────────────────────────────────────────────

    @property
    def is_production(self) -> bool:
        return self.ENV.lower() == "production"

    @property
    def weights_dict(self) -> dict[str, float]:
        """Return weights as a dictionary for easy iteration."""
        return {
            "skills": self.WEIGHT_SKILLS,
            "resume": self.WEIGHT_RESUME,
            "domain": self.WEIGHT_DOMAIN,
            "location": self.WEIGHT_LOCATION,
        }

    def validate_weights(self) -> bool:
        """Check that weights sum to approximately 1.0."""
        total = sum(self.weights_dict.values())
        return 0.99 <= total <= 1.01


# Singleton — import this everywhere
settings = Settings()
