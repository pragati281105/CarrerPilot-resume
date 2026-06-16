# backend/main.py
from dotenv import load_dotenv
load_dotenv()
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from pathlib import Path

from routers.resume import router as resume_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Runs once when the application starts.
    """

    Path("uploads").mkdir(
        parents=True,
        exist_ok=True
    )

    yield

    # Runs once when application shuts down.
    # Add cleanup logic here later if needed.


app = FastAPI(
    title="CareerPilot",
    description=(
        "AI-powered resume analysis and ATS matching platform."
    ),
    version="1.0.0",
    lifespan=lifespan
)

# CORS
# For development only.
# Replace "*" with your frontend URL in production.

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(
    resume_router,
    prefix="/resume",
    tags=["Resume Parser"]
)


@app.get("/")
def home():
    return {
        "message": "CareerPilot API is running"
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy"
    }