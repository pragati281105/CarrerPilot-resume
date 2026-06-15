from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import re
import numpy as np


def preprocess(text: str) -> str:
    text = text.lower()
    text = re.sub(r"http\S+|www\.\S+", "", text)
    text = re.sub(r"\S+@\S+", "", text)
    text = re.sub(r"\b\d{10,}\b", "", text)
    text = re.sub(r"[^\w\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def calculate_similarity(
    resume_text: str,
    jd_text: str,
    chunk_size: int = 256,
    overlap: int = 32,
) -> float:
    if not resume_text.strip() or not jd_text.strip():
        raise ValueError(
            "Both resume_text and jd_text must be non-empty strings."
        )

    clean_resume = preprocess(resume_text)
    clean_jd = preprocess(jd_text)

    vectorizer = TfidfVectorizer()
    tfidf_matrix = vectorizer.fit_transform([clean_resume, clean_jd])

    score = float(
        cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])[0][0]
    ) * 100

    return round(max(0.0, min(score, 100.0)), 2)
