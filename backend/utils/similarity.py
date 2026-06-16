import os
import re
from groq import Groq
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

client = Groq(api_key=os.environ.get("GROQ_API_KEY"))


def preprocess(text: str) -> str:
    text = text.lower()
    text = re.sub(r"http\S+|www\.\S+", "", text)
    text = re.sub(r"\S+@\S+", "", text)
    text = re.sub(r"\b\d{10,}\b", "", text)
    text = re.sub(r"[^\w\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def tfidf_fallback(resume_text: str, jd_text: str) -> float:
    vectorizer = TfidfVectorizer()
    tfidf = vectorizer.fit_transform([
        preprocess(resume_text),
        preprocess(jd_text)
    ])
    score = float(
        cosine_similarity(tfidf[0:1], tfidf[1:2])[0][0]
    ) * 100
    return round(max(0.0, min(score, 100.0)), 2)


def calculate_similarity(
    resume_text: str,
    jd_text: str,
    chunk_size: int = 256,
    overlap: int = 32,
) -> float:
    if not resume_text.strip() or not jd_text.strip():
        raise ValueError(
            "Both resume_text and jd_text must be non-empty."
        )
    try:
        prompt = f"""
You are a senior technical recruiter.
Compare this resume against the job description.
Return ONLY a single float number between 0 and 100 representing
how semantically similar the resume is to the JD.
No explanation. No JSON. Just the number.

RESUME:
{resume_text[:3000]}

JOB DESCRIPTION:
{jd_text[:2000]}
"""
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.0,
            max_tokens=10,
        )
        raw = response.choices[0].message.content.strip()
        score = float(re.sub(r"[^\d.]", "", raw))
        return round(max(0.0, min(score, 100.0)), 2)
    except Exception as e:
        print(f"Groq similarity failed: {e}. Using TF-IDF fallback.")
        return tfidf_fallback(resume_text, jd_text)