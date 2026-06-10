from sentence_transformers import SentenceTransformer
from sentence_transformers.util import cos_sim
import re
import numpy as np


# ── Model ─────────────────────────────────────────────────────────────────────
model = SentenceTransformer("all-MiniLM-L6-v2")


# ── Text Pre-processing ───────────────────────────────────────────────────────
def preprocess(text: str) -> str:
    """
    Clean and normalize raw text before encoding.
    - Lowercases everything so 'Python' and 'python' aren't treated differently.
    - Strips URLs, emails, phone numbers (noise that skews embeddings).
    - Collapses repeated whitespace / newlines into single spaces.
    """
    text = text.lower()
    text = re.sub(r"http\S+|www\.\S+", "", text)      # remove URLs
    text = re.sub(r"\S+@\S+", "", text)               # remove emails
    text = re.sub(r"\b\d{10,}\b", "", text)           # remove phone numbers
    text = re.sub(r"[^\w\s]", " ", text)              # remove punctuation
    text = re.sub(r"\s+", " ", text).strip()          # collapse whitespace
    return text


# ── Chunked Encoding ──────────────────────────────────────────────────────────
def encode_in_chunks(
    text: str,
    chunk_size: int = 256,
    overlap: int = 32,
) -> np.ndarray:
    """
    Split long documents into overlapping word-chunks before encoding,
    then average the chunk embeddings into one document vector.

    Why this matters
    ----------------
    Transformer models have a fixed token limit (usually 512 tokens).
    A long resume fed as a single string gets silently TRUNCATED, so the
    model never sees the second half of the document. Chunking + averaging
    preserves the full content.

    overlap ensures that a skill/phrase that falls right on a chunk
    boundary isn't cut in half and lost.
    """
    if overlap >= chunk_size:
        raise ValueError(
            f"overlap ({overlap}) must be smaller than chunk_size ({chunk_size})"
        )

    words = text.split()

    if len(words) <= chunk_size:
        return model.encode(text, convert_to_tensor=False)

    chunks = []
    start = 0
    while start < len(words):
        end = min(start + chunk_size, len(words))
        chunks.append(" ".join(words[start:end]))
        if end == len(words):
            break
        start += chunk_size - overlap             # slide window with overlap

    embeddings = model.encode(chunks, convert_to_tensor=False, batch_size=16)
    return np.mean(embeddings, axis=0)            # average all chunk vectors


# ── Main Similarity Function ──────────────────────────────────────────────────
def calculate_similarity(
    resume_text: str,
    jd_text: str,
    chunk_size: int = 256,
    overlap: int = 32,
) -> float:
    """
    Compute cosine similarity between a resume and a job description.

    Returns a single float (0-100) so existing callers like agent2_ats.py
    that do `match_score - len(ats_issues) * 5` keep working unchanged.
    All pretty-printing is removed; the caller decides what to display.

    Parameters
    ----------
    resume_text : raw resume string
    jd_text     : raw job-description string
    chunk_size  : words per chunk for long-document encoding
    overlap     : word overlap between consecutive chunks

    Returns
    -------
    float  — similarity score in the range [0.0, 100.0]
    """
    if not resume_text.strip() or not jd_text.strip():
        raise ValueError(
            "Both resume_text and jd_text must be non-empty strings."
        )

    # 1. Clean
    clean_resume = preprocess(resume_text)
    clean_jd     = preprocess(jd_text)

    # 2. Encode (chunked for long docs)
    resume_vec = encode_in_chunks(clean_resume, chunk_size, overlap)
    jd_vec     = encode_in_chunks(clean_jd,     chunk_size, overlap)

    # 3. Cosine similarity → 0-100 score
    # cos_sim expects 2-D tensors; reshape from (dim,) → (1, dim)
    score = float(
        cos_sim(
            resume_vec.reshape(1, -1),
            jd_vec.reshape(1, -1),
        ).item()
    ) * 100

    # 4. Clamp to [0, 100] and return
    return round(max(0.0, min(score, 100.0)), 2)