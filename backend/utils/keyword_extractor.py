# backend/utils/keyword_extractor.py

import re

# ── Known Technical Skills ────────────────────────────────────────────────────
# Organized by category for readability and easier future maintenance.
# Adding a new skill here automatically makes it detectable everywhere.
TECH_SKILLS = {
    # Languages
    "python", "java", "javascript", "typescript", "c++", "c#", "r", "go",
    "rust", "scala", "kotlin", "swift",

    # Databases
    "sql", "mysql", "postgresql", "mongodb", "redis", "sqlite",
    "elasticsearch", "cassandra",

    # Web Frameworks
    "fastapi", "django", "flask", "react", "angular", "vue",
    "nodejs", "express", "nextjs", "spring",

    # DevOps & Cloud
    "docker", "kubernetes", "git", "github", "gitlab", "aws", "azure",
    "gcp", "terraform", "ci/cd", "jenkins", "linux",

    # Data & ML
    "machine learning", "deep learning", "tensorflow", "pytorch", "nlp",
    "data analysis", "pandas", "numpy", "scikit-learn", "opencv",
    "data science", "computer vision", "llm", "generative ai",

    # Soft / Process Skills
    "agile", "scrum", "rest api", "microservices", "system design",
}


# ── Helpers ───────────────────────────────────────────────────────────────────
def _build_patterns() -> dict[str, re.Pattern]:
    """
    Pre-compile a regex pattern for every skill once at import time.

    Uses lookaround assertions instead of \\b word boundaries.

    Why lookarounds instead of \\b?
    --------------------------------
    \\b only works correctly when a skill starts AND ends with a word
    character (a-z, 0-9, _). Skills like 'c++', 'c#', and 'ci/cd' end
    with non-word characters, so \\b fails to anchor them correctly and
    they either never match or match inside longer strings.

    (?<!\\w)  — negative lookbehind: no word character immediately before
    (?!\\w)   — negative lookahead:  no word character immediately after

    This correctly handles all of:
        c++   c#   ci/cd   rest api   machine learning   python
    """
    return {
        skill: re.compile(
            rf"(?<!\w){re.escape(skill)}(?!\w)",
            re.IGNORECASE,
        )
        for skill in TECH_SKILLS
    }

# Module-level cache — compiled once when the file is first imported.
_PATTERNS: dict[str, re.Pattern] = _build_patterns()


# ── Core Functions ────────────────────────────────────────────────────────────
def extract_keywords(text: str) -> set[str]:
    """
    Extract known technical skills from text using pre-compiled patterns.

    Parameters
    ----------
    text : raw string (resume or JD)

    Returns
    -------
    set of matched skill strings (lowercase)
    """
    if not text or not text.strip():
        return set()

    found: set[str] = set()
    for skill, pattern in _PATTERNS.items():
        if pattern.search(text):
            found.add(skill)
    return found


def compare_keywords(
    resume_text: str,
    jd_text: str,
) -> dict[str, list | float]:
    """
    Compare skills found in a resume against skills required in a JD.

    Parameters
    ----------
    resume_text : raw resume string
    jd_text     : raw job-description string

    Returns
    -------
    {
        "resume_keywords"  : list   # all skills found in resume
        "jd_keywords"      : list   # all skills found in JD
        "matched_keywords" : list   # skills present in both
        "missing_keywords" : list   # JD skills absent from resume
        "match_rate"       : float  # matched / jd_keywords as a percentage
    }
    """
    resume_keywords = extract_keywords(resume_text)
    jd_keywords     = extract_keywords(jd_text)

    matched = jd_keywords & resume_keywords
    missing = jd_keywords - resume_keywords

    # Avoid division by zero when JD has no recognised skills
    match_rate = (
        round(len(matched) / len(jd_keywords) * 100, 1)
        if jd_keywords else 0.0
    )

    return {
        "resume_keywords"  : sorted(resume_keywords),
        "jd_keywords"      : sorted(jd_keywords),
        "matched_keywords" : sorted(matched),
        "missing_keywords" : sorted(missing),
        "match_rate"       : match_rate,        # e.g. 66.7  (means 66.7 %)
    }