from fastapi import APIRouter

from app.api import assets, auth, health, management, monitoring, projects, scans

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(health.router)
api_router.include_router(projects.router)
api_router.include_router(assets.router)
api_router.include_router(scans.router)
api_router.include_router(monitoring.router)
api_router.include_router(management.router)
