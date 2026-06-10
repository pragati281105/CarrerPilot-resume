# backend/utils/ats_checker.py

from utils.keyword_extractor import compare_keywords

# ── Penalty Configuration ─────────────────────────────────────────────────────
# Defined at the top so tuning the penalty never requires touching
# business logic inside the function.
PENALTY_PER_MISSING_SKILL = 5
MAX_PENALTY               = 50     # cap so one bad resume doesn't score below 0


# ── ATS Checker ───────────────────────────────────────────────────────────────
def check_ats(
    resume_text: str,
    jd_text: str,
) -> dict[str, list | int | float]:
    """
    Analyze ATS compatibility using keyword coverage.

    Parameters
    ----------
    resume_text : raw resume string
    jd_text     : raw job-description string

    Returns
    -------
    {
        "issues"           : list[str]   # human-readable issue per missing skill
        "penalty"          : int         # score deduction (capped at MAX_PENALTY)
        "matched_keywords" : list[str]   # skills present in both resume and JD
        "missing_keywords" : list[str]   # JD skills absent from resume
        "match_rate"       : float       # matched / jd_keywords as a percentage
        "severity"         : str         # Low / Medium / High based on penalty
    }
    """
    keyword_data = compare_keywords(
        resume_text=resume_text,
        jd_text=jd_text,
    )

    missing: list[str] = list(keyword_data["missing_keywords"])
    matched: list[str] = list(keyword_data["matched_keywords"])

    # ── Issues ────────────────────────────────────────────────────────────────
    # More descriptive message format — tells the candidate exactly what to add
    # rather than just flagging the absence.
    issues = [
        f"Missing keyword: '{kw}' — consider adding it if applicable"
        for kw in missing
    ]

    # ── Penalty ───────────────────────────────────────────────────────────────
    # Raw penalty is capped at MAX_PENALTY so a resume with many gaps
    # doesn't produce a nonsense negative ATS score downstream.
    raw_penalty = len(missing) * PENALTY_PER_MISSING_SKILL
    penalty     = min(raw_penalty, MAX_PENALTY)

    # ── Severity ──────────────────────────────────────────────────────────────
    # Gives the caller (and any frontend) a quick human-readable signal
    # without needing to interpret the raw penalty number themselves.
    if penalty <= 10:
        severity = "Low"
    elif penalty <= 30:
        severity = "Medium"
    else:
        severity = "High"

    return {
        "issues"           : issues,
        "penalty"          : penalty,
        "matched_keywords" : matched,
        "missing_keywords" : missing,
        "match_rate"       : keyword_data["match_rate"],
        "severity"         : severity,
    }