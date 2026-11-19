import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from library import config, db, limits, migrations
from library.metadata import deezer
from library.routes import account, catalog, playback, sync
from library.track import downloads, loudness

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")


@asynccontextmanager
async def lifespan(_: FastAPI):
    config.AUDIO_DIR.mkdir(parents=True, exist_ok=True)
    config.TEMP_DIR.mkdir(parents=True, exist_ok=True)
    downloads.clear_streams()
    await db.pool.open(wait=True)
    await migrations.apply_pending()
    measuring = asyncio.create_task(loudness.measure_stored())
    yield
    measuring.cancel()
    await deezer.close()
    await db.pool.close()


app = FastAPI(title="Pongo", lifespan=lifespan, docs_url=None, redoc_url=None)
app.include_router(account.router)
app.include_router(catalog.router)
app.include_router(playback.router)
app.include_router(sync.router)


@app.middleware("http")
async def limit_requests(request: Request, call_next):
    # The player fetches audio in many small range requests, so those aren't counted
    if not request.url.path.startswith(("/play_song", "/stream/")) and not limits.requests.allow(
        limits.client_ip(request)
    ):
        return JSONResponse(status_code=429, content={"detail": "Too many requests"})
    return await call_next(request)


@app.exception_handler(deezer.DeezerError)
async def catalog_error(_: Request, error: deezer.DeezerError):
    logging.getLogger(__name__).warning("Catalog error: %s", error)
    return JSONResponse(status_code=502, content={"detail": "Catalog unavailable"})


@app.get("/health")
async def health():
    await db.fetch_one("SELECT 1")
    return {"status": "ok"}
