"""
Global Error Handler — Catches unhandled exceptions.

In production, we never want raw stack traces leaking to clients.
This middleware catches everything that the route handlers miss
and returns a clean JSON error response.
"""

import logging
from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse

logger = logging.getLogger("app.errors")


async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """
    Catch-all exception handler registered via app.add_exception_handler.

    - Logs the full traceback server-side for internal 500-level errors.
    - If it's an explicitly raised HTTPException (like our custom exceptions),
      it passes the detail and status code through safely without logging a 500 traceback.
    """
    request_id = getattr(request.state, "request_id", "unknown")

    # Pass through intentional HTTP Exceptions without full tracebacks
    if isinstance(exc, HTTPException):
        from typing import cast
        http_exc = cast(HTTPException, exc)
        logger.warning(
            f"{request.method} {request.url.path} → {http_exc.status_code} "
            f"({http_exc.detail}) [req_{request_id}]"
        )
        return JSONResponse(
            status_code=http_exc.status_code,
            content={"detail": http_exc.detail, "request_id": request_id},
        )

    # Handled as unexpected internal server error
    logger.error(
        f"Unhandled exception on {request.method} {request.url.path} "
        f"[req_{request_id}]: {exc}",
        exc_info=True,
    )

    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error",
            "request_id": request_id,
        },
    )
