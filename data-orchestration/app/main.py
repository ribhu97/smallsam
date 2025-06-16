from fastapi import FastAPI
from celery import Celery

app = FastAPI(
    title="Small Sam Data Orchestration",
    description="Data ingestion and processing service",
    version="0.1.0",
)

celery = Celery(
    "data_orchestration",
    broker="redis://localhost:6379/2",
    backend="redis://localhost:6379/3"
)


@app.get("/")
async def root():
    return {"message": "Small Sam Data Orchestration"}


@app.get("/health")
async def health():
    return {"status": "healthy", "service": "data-orchestration"}