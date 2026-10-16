from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api import api_router
from app.core.config import get_settings


def _validation_message(exc: RequestValidationError) -> str:
    for error in exc.errors():
        message = error.get("msg")
        if isinstance(message, str):
            if message.startswith("Value error, "):
                message = message[len("Value error, ") :]
            return message
    return "Data yang dikirim tidak valid."


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="Pulse API", version="0.1.0")

    origins = settings.cors_origin_list
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
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
