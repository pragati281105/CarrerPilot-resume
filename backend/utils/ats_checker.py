import os
import json
import re
from groq import Groq
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

client = Groq(api_key=os.environ.get("GROQ_API_KEY"))


def _extract_jd_keywords(jd_text: str) -> dict:
    prompt = f"""
Extract keywords from this job description.
Return ONLY valid JSON, no explanation, no markdown.

JOB DESCRIPTION:
{jd_text[:2000]}

Return exactly:
{{
  "required_skills": ["skill1", "skill2"],
  "preferred_skills": ["skill1", "skill2"],
  "ats_keywords": ["keyword1", "keyword2"]
}}
"""
    try:
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.0,
            max_tokens=800,
        )
        raw = response.choices[0].message.content.strip()
        raw = re.sub(r"^```json\s*", "", raw)
        raw = re.sub(r"^```\s*", "", raw)
        raw = re.sub(r"\s*```$", "", raw)
        return json.loads(raw)
    except Exception as e:
        print(f"Groq keyword extraction failed: {e}")
        return {
            "required_skills": [],
            "preferred_skills": [],
            "ats_keywords": []
        }


def _keyword_overlap(resume_text: str, keywords: list) -> tuple:
    resume_lower = resume_text.lower()
    matched = []
    missing = []
    for kw in keywords:
        if kw.lower() in resume_lower:
            matched.append(kw)
        else:
            missing.append(kw)
    return matched, missing


def check_ats(resume_text: str, jd_text: str) -> dict:
    jd_keywords = _extract_jd_keywords(jd_text)

    required_skills  = jd_keywords.get("required_skills", [])
    preferred_skills = jd_keywords.get("preferred_skills", [])
    ats_keywords     = jd_keywords.get("ats_keywords", [])

    req_matched,  req_missing  = _keyword_overlap(resume_text, required_skills)
    pref_matched, pref_missing = _keyword_overlap(resume_text, preferred_skills)
    ats_matched,  ats_missing  = _keyword_overlap(resume_text, ats_keywords)

    all_matched = req_matched + pref_matched + ats_matched
    all_missing = req_missing + pref_missing + ats_missing

    penalty = min(len(req_missing)  * 5, 40) + \
              min(len(pref_missing) * 2, 10) + \
              min(len(ats_missing)  * 1, 10)
    penalty = min(penalty, 60)

    total_required = len(required_skills) + len(ats_keywords)
    total_matched  = len(req_matched) + len(ats_matched)
    match_rate = round(
        (total_matched / total_required * 100) if total_required > 0 else 100.0,
        2
    )

    missing_required_count = len(req_missing)
    if missing_required_count == 0:
        severity = "Low"
    elif missing_required_count <= 2:
        severity = "Medium"
    else:
        severity = "High"

    issues = []
    for skill in req_missing[:5]:
        issues.append(f"Missing required skill: {skill}")
    for skill in pref_missing[:3]:
        issues.append(f"Missing preferred skill: {skill}")

    return {
        "penalty"          : penalty,
        "severity"         : severity,
        "match_rate"       : match_rate,
        "matched_keywords" : all_matched,
        "missing_keywords" : all_missing,
        "issues"           : issues,
    }