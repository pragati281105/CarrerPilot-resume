from pathlib import Path
from utils.file_parser import (
    parse_pdf,
    parse_docx,
    parse_image
)
from utils.jd_parser import (
    extract_jd_from_url,
    process_raw_jd
)
class Agent1Parser:
    @staticmethod
    def parse_resume(file_path: str) -> str:
        file = Path(file_path)
        if not file.exists():
            raise FileNotFoundError(
                f"File not found: {file_path}"
            )
        extension = file.suffix.lower()
        if extension == ".pdf":
            return parse_pdf(file_path)
        elif extension == ".docx":
            return parse_docx(file_path)
        elif extension in [".png", ".jpg", ".jpeg"]:
            return parse_image(file_path)
        raise ValueError(
            f"Unsupported file type: {extension}"
        )
    @staticmethod
    async def parse_job_description(
        jd_url: str | None = None,
        jd_text: str | None = None
    ) -> str:
        if jd_url and jd_url.strip():
            return await extract_jd_from_url(jd_url)

        if jd_text and jd_text.strip():
            return process_raw_jd(jd_text)
        raise ValueError(
            "Either jd_url or jd_text must be provided."
        )
    @classmethod
    async def process(
        cls,
        resume_file_path: str,
        jd_url: str | None = None,
        jd_text: str | None = None
    ) -> dict:
        resume_text = cls.parse_resume(
            resume_file_path
        )
        jd_text_result = await cls.parse_job_description(
            jd_url=jd_url,
            jd_text=jd_text
        )
        return {
            "resume_text": resume_text,
            "jd_text": jd_text_result
        }