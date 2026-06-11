import re
import httpx
from bs4 import BeautifulSoup

# Realistic browser header — prevents 403 blocks on most job boards
HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "en-US,en;q=0.9",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
}


async def extract_jd_from_url(url: str) -> str:
    """
    Extract job description text from a job posting URL.

    Uses a browser User-Agent to avoid 403 blocks.
    Targets main content containers before falling back to full page.
    """

    try:
        async with httpx.AsyncClient(
            timeout=20,
            follow_redirects=True,
            headers=HEADERS
        ) as client:

            response = await client.get(url)

            response.raise_for_status()

    except httpx.TimeoutException:
        raise ValueError(
            f"Request timed out while fetching the job URL: {url}. "
            "Check your internet connection or try pasting the JD manually."
        )

    except httpx.HTTPStatusError as e:
        raise ValueError(
            f"Job page returned HTTP {e.response.status_code} for URL: {url}. "
            "The page may require login or is no longer available. "
            "Try pasting the JD text manually instead."
        )

    except httpx.RequestError as e:
        raise ValueError(
            f"Failed to reach the job URL: {url}. Error: {str(e)}"
        )

    soup = BeautifulSoup(
        response.text,
        "html.parser"
    )

    # Remove noisy tags first
    for tag in soup(
        [
            "script",
            "style",
            "header",
            "footer",
            "nav",
            "noscript",
            "aside"
        ]
    ):
        tag.decompose()

    # Try to find the main content container
    # Job boards almost always put JD inside one of these

    jd_text = ""

    for selector in [
        "main",
        "article",
        "[class*='job-description']",
        "[class*='jobDescription']",
        "[class*='description']",
        "[id*='job-description']",
        "[id*='jobDescription']"
    ]:

        container = soup.select_one(selector)

        if container:

            candidate = container.get_text(
                separator=" ",
                strip=True
            )

            # Only use this container if it has meaningful content
            if len(candidate) > 200:
                jd_text = candidate
                break

    # Fallback: use full page text if no container matched

    if not jd_text:
        jd_text = soup.get_text(
            separator=" ",
            strip=True
        )

    # Normalize whitespace

    jd_text = re.sub(
        r"\s+",
        " ",
        jd_text
    )

    return jd_text.strip()


def process_raw_jd(jd_text: str) -> str:
    """
    Clean job description pasted directly by user.

    Normalizes whitespace and line breaks.
    """

    if not jd_text or not jd_text.strip():
        raise ValueError(
            "Job description cannot be empty."
        )

    # Normalize all whitespace to single spaces

    cleaned = re.sub(
        r"[ \t]+",
        " ",
        jd_text
    )

    # Preserve intentional line breaks

    cleaned = re.sub(
        r"\n{3,}",
        "\n\n",
        cleaned
    )

    return cleaned.strip()