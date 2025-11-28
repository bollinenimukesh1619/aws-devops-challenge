from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI()


@app.get("/", response_class=JSONResponse)
def read_root():
    """Return the static greeting payload required by the spec."""
    return {"message": "Hello, Candidate", "version": "1.0.0"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=80)
