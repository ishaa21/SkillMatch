"""
Request Logging Middleware — Logs every incoming request.

For production observability. Logs:
  - Method, path, status code
  - Response time in ms
  - A unique request ID (for tracing across services)

Example log line:
  POST /recommend → 200 (142ms) [req_abc123]
"""

import time
import uuid
import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger("app.access")


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Logs method, path, status, and latency for every request."""

    async def dispatch(self, request: Request, call_next) -> Response:
        request_id = str(uuid.uuid4())[:8]
        start = time.time()

        # Attach request ID to request state so handlers can use it
        request.state.request_id = request_id

        response: Response = await call_next(request)

        elapsed_ms = round((time.time() - start) * 1000)
        logger.info(
            f"{request.method} {request.url.path} → {response.status_code} "
            f"({elapsed_ms}ms) [req_{request_id}]"
        )

        # Add request ID to response headers for client-side tracing
        response.headers["X-Request-ID"] = request_id
        return response
