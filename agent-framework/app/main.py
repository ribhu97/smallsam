from fastapi import FastAPI

app = FastAPI(
    title="Small Sam Agent Framework",
    description="Multi-agent AI system for FPL analysis",
    version="0.1.0",
)


@app.get("/")
async def root():
    return {"message": "Small Sam Agent Framework"}


@app.get("/health")
async def health():
    return {"status": "healthy", "service": "agent-framework"}