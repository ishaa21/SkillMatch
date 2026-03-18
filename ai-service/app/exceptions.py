"""
Custom Exception Classes for the AI Microservice.

These exceptions are caught by the global error handler (`error_handler.py`)
and mapped to appropriate HTTP status codes, preventing raw stack traces
from leaking while keeping log messages descriptive.
"""

from fastapi import HTTPException
from pydantic import BaseModel


class AIServiceException(HTTPException):
    """Base class for all specific AI service exceptions."""
    def __init__(self, status_code: int, detail: str):
        super().__init__(status_code=status_code, detail=detail)


class ModelNotLoadedError(AIServiceException):
    """Raised when an operation requires the ML model but it hasn't finished loading."""
    def __init__(self, detail: str = "ML model is currently loading or unavailable."):
        super().__init__(status_code=503, detail=detail)


class InvalidInputError(AIServiceException):
    """Raised when the input payload is logically invalid (e.g., negative score weights)."""
    def __init__(self, detail: str):
        super().__init__(status_code=400, detail=detail)


class ServiceUnavailableError(AIServiceException):
    """Raised when a dependency (like a database or upstream service) is down."""
    def __init__(self, detail: str = "Underlying service dependency is unavailable."):
        super().__init__(status_code=503, detail=detail)
