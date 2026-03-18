import logging
import sys
from pythonjsonlogger import jsonlogger

from app.config.settings import settings


def setup_logging():
    """
    Configures the root logger.
    
    If ENV == "production", uses a structured JSON formatter so logs can be
    easily ingested by Datadog/ELK/CloudWatch.
    Otherwise, uses a human-readable text formatter for local development.
    """
    logger = logging.getLogger()
    
    # clear existing handlers if any
    if logger.hasHandlers():
        logger.handlers.clear()

    # Get log level from settings (e.g. "INFO", "DEBUG")
    log_level = getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO)
    logger.setLevel(log_level)

    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(log_level)

    if settings.is_production:
        # Structured JSON logs for production
        formatter = jsonlogger.JsonFormatter(
            "%(asctime)s %(levelname)s %(name)s %(message)s",
            rename_fields={"levelname": "severity", "asctime": "timestamp"}
        )
    else:
        # Human-readable color/text logs for dev
        formatter = logging.Formatter(
            "%(asctime)s | %(levelname)-7s | %(name)s | %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S"
        )

    handler.setFormatter(formatter)
    logger.addHandler(handler)

    # Disable overly verbose third-party loggers
    logging.getLogger("sentence_transformers").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)
