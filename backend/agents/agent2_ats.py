# backend/agents/agent2_ats.py

from utils.similarity import calculate_similarity
from utils.ats_checker import check_ats

# ── Match Band Thresholds ─────────────────────────────────────────────────────
# Defined once here so changing a threshold updates both verdict and
# recommendation without touching two separate places.
MATCH_BANDS = [
    (75, "Strong Match",   "Proceed to interview — resume aligns well with the JD."),
    (55, "Moderate Match", "Consider with minor gaps; a cover letter addressing missing skills helps."),
    (35, "Weak Match",     "Significant skill gaps; resume needs targeted updates before applying."),
    (0,  "Poor Match",     "Resume and JD are largely misaligned; reconsider the role or rework resume."),
]


# ── Band Lookup ───────────────────────────────────────────────────────────────
def _get_band(score: float) -> tuple[str, str]:
    """Return (verdict, recommendation) for a given score."""
    for threshold, verdict, recommendation in MATCH_BANDS:
        if score >= threshold:
            return verdict, recommendation

    # Fallback — never reached under normal conditions since MATCH_BANDS
    # contains a (0, ...) entry and scores are clamped to [0, 100].
    # Guards against accidental MATCH_BANDS edits or out-of-range test values.
    return (
        "Poor Match",
        "Resume and JD are largely misaligned; reconsider the role or rework resume.",
    )


# ── Agent ─────────────────────────────────────────────────────────────────────
class Agent2ATS:
    """
    Agent 2:
    - Receives parsed resume text and JD text
    - Calculates semantic similarity score
    - Applies ATS keyword penalty
    - Returns full ATS evaluation
    """

    @staticmethod
    def evaluate(
        resume_text: str,
        jd_text: str,
    ) -> dict[str, float | str | list]:
        """
        Parameters
        ----------
        resume_text : raw resume string
        jd_text     : raw job-description string

        Returns
        -------
        {
            "final_score"          : float   # penalty-adjusted score, 0–100
            "similarity_score"     : float   # raw semantic similarity, 0–100
            "penalty"              : int     # deduction applied (capped)
            "verdict"              : str     # Strong / Moderate / Weak / Poor Match
            "recommendation"       : str     # one-line action hint
            "severity"             : str     # Low / Medium / High keyword gap
            "match_rate"           : float   # keyword match percentage
            "matched_keywords"     : list    # skills present in both
            "missing_keywords"     : list    # JD skills absent from resume
            "ats_issues"           : list    # human-readable issue per missing skill
        }
        """
        # 1. Semantic similarity (0–100 float)
        similarity_score = calculate_similarity(
            resume_text=resume_text,
            jd_text=jd_text,
        )

        # 2. ATS keyword analysis
        ats_result = check_ats(
            resume_text=resume_text,
            jd_text=jd_text,
        )

        # 3. Apply penalty — clamp to [0, 100]
        # Upper-bound added so an unexpectedly low penalty never
        # pushes an already-high similarity above 100.
        final_score = round(
            max(0.0, min(100.0, similarity_score - ats_result["penalty"])),
            2,
        )

        # 4. Derive verdict and recommendation from final score
        verdict, recommendation = _get_band(final_score)

        return {
            "final_score"      : final_score,
            "similarity_score" : similarity_score,
            "penalty"          : ats_result["penalty"],
            "verdict"          : verdict,
            "recommendation"   : recommendation,
            "severity"         : ats_result["severity"],
            "match_rate"       : ats_result["match_rate"],
            "matched_keywords" : ats_result["matched_keywords"],
            "missing_keywords" : ats_result["missing_keywords"],
            "ats_issues"       : ats_result["issues"],
        }