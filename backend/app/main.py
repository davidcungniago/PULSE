import logging
from time import monotonic
from uuid import uuid4

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api import api_router
from app.core.config import get_settings
from app.services.safe_logging import request_log


def _validation_message(exc: RequestValidationError) -> str:
    for error in exc.errors():
        message = error.get("msg")
        if isinstance(message, str):
            if message.startswith("Value error, "):
                message = message[len("Value error, ") :]
                return message
            if error.get("type") == "missing":
                return "Data wajib belum diisi."
            return "Format data yang dikirim tidak valid."
    return "Data yang dikirim tidak valid."


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="Pulse API", version="0.1.0")

    @app.middleware("http")
    async def safe_request_logging(request: Request, call_next):
        request_id = uuid4().hex
        started = monotonic()
        try:
            response = await call_next(request)
        except Exception:
            response = JSONResponse(
                status_code=500, content={"Message": "Terjadi kesalahan pada server."}
            )
        route = getattr(request.scope.get("route"), "path", "<unmatched>")
        logging.getLogger("uvicorn.error").info(
            request_log(
                request_id,
                request.method
                if request.method in {"GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"}
                else "OTHER",
                route,
                response.status_code,
                round((monotonic() - started) * 1000),
            )
        )
        response.headers["X-Request-ID"] = request_id
        return response

    origins = settings.cors_origin_list
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_origin_regex=settings.cors_origin_regex or None,
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.exception_handler(HTTPException)
    async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
        return JSONResponse(status_code=exc.status_code, content={"Message": exc.detail})

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        return JSONResponse(status_code=422, content={"Message": _validation_message(exc)})

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        return JSONResponse(
            status_code=500,
            content={"Message": "Terjadi kesalahan pada server."},
        )

    app.include_router(api_router)
    return app


app = create_app()
