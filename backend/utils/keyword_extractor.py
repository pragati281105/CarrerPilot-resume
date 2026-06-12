# backend/utils/keyword_extractor.py

import re

TECH_SKILLS = {
    "python", "java", "javascript", "typescript",
    "sql", "mysql", "postgresql", "mongodb",
    "fastapi", "django", "flask", "react",
    "docker", "kubernetes", "aws", "azure",
    "tensorflow", "pytorch", "machine learning",
    "deep learning", "nlp", "llm",
    "generative ai", "data science",
}

STOP_WORDS = {
    "and", "or", "the", "a", "an", "to", "of",
    "for", "with", "in", "on", "at", "is",
    "are", "will", "must", "should", "using",
    "experience", "required", "preferred",
    "candidate", "job", "role", "team",
}


def extract_dynamic_keywords(text: str) -> set[str]:
    """
    Extract important words directly from JD.
    """

    words = re.findall(
        r"\b[a-zA-Z][a-zA-Z0-9+#./-]*\b",
        text.lower(),
    )

    return {
        word
        for word in words
        if len(word) > 2
        and word not in STOP_WORDS
    }


def extract_keywords(text: str) -> set[str]:
    """
    Hybrid extraction:
    1. Known technical skills
    2. Dynamic JD-specific keywords
    """

    text_lower = text.lower()

    found_skills = {
        skill
        for skill in TECH_SKILLS
        if skill in text_lower
    }

    dynamic_keywords = extract_dynamic_keywords(
        text_lower
    )

    return found_skills.union(dynamic_keywords)


def compare_keywords(
    resume_text: str,
    jd_text: str,
):
    resume_keywords = extract_keywords(
        resume_text
    )

    jd_keywords = extract_keywords(
        jd_text
    )

    matched = (
        resume_keywords &
        jd_keywords
    )

    missing = (
        jd_keywords -
        resume_keywords
    )

    match_rate = (
        round(
            len(matched)
            / len(jd_keywords)
            * 100,
            1,
        )
        if jd_keywords
        else 0.0
    )

    return {
        "resume_keywords":
            sorted(resume_keywords),

        "jd_keywords":
            sorted(jd_keywords),

        "matched_keywords":
            sorted(matched),

        "missing_keywords":
            sorted(missing),

        "match_rate":
            match_rate,
    }