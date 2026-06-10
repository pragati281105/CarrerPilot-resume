from agents.agent2_ats import Agent2ATS

resume_text = """
Python developer with FastAPI, Docker, Git and PostgreSQL experience.
Built REST APIs and deployed applications using AWS.
"""

jd_text = """
Looking for a Python developer with FastAPI, Docker, SQL, Git, AWS and Kubernetes experience.
"""

result = Agent2ATS.evaluate(
    resume_text=resume_text,
    jd_text=jd_text
)

print("\n===== AGENT 2 RESULT =====")
print(result)