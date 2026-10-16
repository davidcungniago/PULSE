from fastapi import APIRouter

from app.api import assets, health, projects, scans

api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(projects.router)
api_router.include_router(assets.router)
api_router.include_router(scans.router)
