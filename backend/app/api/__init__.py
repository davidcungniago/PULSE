from fastapi import APIRouter

from app.api import assets, health, projects

api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(projects.router)
api_router.include_router(assets.router)
