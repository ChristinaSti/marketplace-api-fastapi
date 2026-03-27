from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def read_root():
    return {"message": "Hello, World!"}


@app.get("/health")
def health():
    """Liveness/startup probe for Cloud Run."""
    return {"status": "ok"}
