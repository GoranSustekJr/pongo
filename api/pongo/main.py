import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from library import config, db
from library.metadata import deezer
from library.routes import account, catalog, playback

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")


@asynccontextmanager
async def lifespan(_: FastAPI):
    config.AUDIO_DIR.mkdir(parents=True, exist_ok=True)
    config.TEMP_DIR.mkdir(parents=True, exist_ok=True)
    await db.pool.open(wait=True)
    yield
    await deezer.close()
    await db.pool.close()


app = FastAPI(title="Pongo", lifespan=lifespan, docs_url=None, redoc_url=None)
app.include_router(account.router)
app.include_router(catalog.router)
app.include_router(playback.router)


@app.exception_handler(deezer.DeezerError)
async def catalog_error(_: Request, error: deezer.DeezerError):
    logging.getLogger(__name__).warning("Catalog error: %s", error)
    return JSONResponse(status_code=502, content={"detail": "Catalog unavailable"})


@app.get("/health")
async def health():
    await db.fetch_one("SELECT 1")
    return {"status": "ok"}
