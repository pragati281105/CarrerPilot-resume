# backend/routers/resume.py

import uuid
import os

from fastapi import (
    APIRouter,
    UploadFile,
    File,
    Form,
    HTTPException
)

from pathlib import Path

from agents.agent1_parser import Agent1Parser

router = APIRouter()

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(
    parents=True,
    exist_ok=True
)

ALLOWED_EXTENSIONS = {
    ".pdf",
    ".docx",
    ".png",
    ".jpg",
    ".jpeg"
}


@router.post("/upload-resume")
async def upload_resume(
    resume: UploadFile = File(...),
    jd_url: str | None = Form(None),
    jd_text: str | None = Form(None)
):
    """
    Upload a resume and either:
    - jd_url
    OR
    - jd_text

    Returns:
    {
        "resume_text": "...",
        "jd_text": "..."
    }
    """

    # Validate filename

    if not resume.filename:
        raise HTTPException(
            status_code=400,
            detail="No file selected."
        )

    # Validate file type

    extension = Path(
        resume.filename
    ).suffix.lower()

    if extension not in ALLOWED_EXTENSIONS:

        raise HTTPException(
            status_code=400,
            detail=(
                f"Unsupported file type: '{extension}'. "
                f"Allowed types: "
                f"{', '.join(ALLOWED_EXTENSIONS)}"
            )
        )

    # Validate JD input

    if not (
        (jd_url and jd_url.strip())
        or
        (jd_text and jd_text.strip())
    ):
        raise HTTPException(
            status_code=422,
            detail=(
                "Either jd_url or jd_text "
                "must be provided."
            )
        )

    # Prevent filename collisions

    unique_filename = (
        f"{uuid.uuid4().hex}"
        f"{extension}"
    )

    file_path = (
        UPLOAD_DIR /
        unique_filename
    )

    try:

        # Save uploaded file

        contents = await resume.read()

        with open(
            file_path,
            "wb"
        ) as f:

            f.write(contents)

        # Run Agent 1

        result = await Agent1Parser.process(
            resume_file_path=str(file_path),
            jd_url=jd_url,
            jd_text=jd_text
        )

        return result

    except ValueError as e:

        raise HTTPException(
            status_code=400,
            detail=str(e)
        )

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=(
                "Internal error during "
                f"resume processing: {str(e)}"
            )
        )

    finally:

        # Always delete temp file

        if file_path.exists():
            os.remove(file_path)