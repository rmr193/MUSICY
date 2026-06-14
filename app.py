import asyncio
import logging
import re
import time
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, Query, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import RedirectResponse
from fastapi.middleware.cors import CORSMiddleware
from ytmusicapi import YTMusic
import yt_dlp

BASE_DIR = Path(__file__).resolve().parent
STATIC_DIR = BASE_DIR / "static"
STREAM_CACHE_TTL_SECONDS = 60 * 60 * 6
YOUTUBE_VIDEO_ID_RE = re.compile(r"^[A-Za-z0-9_-]{6,20}$")

logger = logging.getLogger("musicy")

app = FastAPI(title="MUSICY")

# Enable CORS for all origins (adjust in production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

ytmusic = YTMusic()

# Simple in-memory cache for stream URLs: {videoId: (stream_url, expiry_timestamp)}
stream_cache: dict[str, tuple[str, float]] = {}

# Serve static files (HTML/CSS/JS) at /web
app.mount("/web", StaticFiles(directory=STATIC_DIR, html=True), name="web")

# Root endpoint redirects to the web UI
@app.get("/")
async def root():
    return RedirectResponse(url="/web/")


@app.get("/songs/search/", summary="Search songs on YouTube Music")
async def songs_search(
    query: str = Query(min_length=1, max_length=120, description="Song name to search for"),
    limit: Optional[int] = Query(default=15, ge=1, le=25),
):
    search_term = query.strip()
    if not search_term:
        raise HTTPException(status_code=422, detail="Search query cannot be empty")

    def perform_search():
        return ytmusic.search(search_term, filter="songs", limit=limit)

    try:
        loop = asyncio.get_running_loop()
        raw = await loop.run_in_executor(None, perform_search)
    except Exception as e:
        logger.exception("YouTube Music search failed")
        raise HTTPException(status_code=502, detail="Music search is temporarily unavailable") from e

    results = []
    for item in raw[:limit]:
        # Extract thumbnail (largest available)
        thumbs = item.get("thumbnails", [])
        thumbnail = thumbs[-1]["url"] if thumbs else ""

        # Artists can be a list of dicts
        artists_raw = item.get("artists", [])
        if isinstance(artists_raw, list):
            artist_str = ", ".join(a.get("name", "") for a in artists_raw)
        else:
            artist_str = str(artists_raw)

        album = item.get("album", {})
        album_name = album.get("name", "") if isinstance(album, dict) else ""

        results.append({
            "videoId": item.get("videoId", ""),
            "title": item.get("title", "Unknown"),
            "artists": artist_str,
            "album": album_name,
            "duration": item.get("duration", ""),
            "duration_seconds": item.get("duration_seconds", 0),
            "thumbnail": thumbnail,
        })

    return results


@app.get("/songs/stream/", summary="Get streamable audio URL for a song")
async def songs_stream(
    videoId: str = Query(description="YouTube videoId of the song"),
):
    if not YOUTUBE_VIDEO_ID_RE.fullmatch(videoId):
        raise HTTPException(status_code=422, detail="Invalid YouTube videoId")

    # Check in-memory stream cache (expiry is 6 hours)
    now = time.time()
    if videoId in stream_cache:
        cached_url, expiry = stream_cache[videoId]
        if now < expiry:
            return {"stream_url": cached_url}
        del stream_cache[videoId]

    url = f"https://www.youtube.com/watch?v={videoId}"
    ydl_opts = {
        "format": "bestaudio[ext=webm]/bestaudio[ext=m4a]/bestaudio/best",
        "quiet": True,
        "no_warnings": True,
        "extract_flat": False,
        "nocheckcertificate": True,
        "skip_download": True,
        "check_formats": False,  # Skip check for faster extraction
        "youtube_include_dash_manifest": False,
        "youtube_include_hls_manifest": False,
    }

    def extract():
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            return info.get("url", "")

    try:
        loop = asyncio.get_running_loop()
        stream_url = await loop.run_in_executor(None, extract)
    except Exception as e:
        logger.exception("Could not extract stream for videoId=%s", videoId)
        raise HTTPException(status_code=502, detail="Could not extract stream for this track") from e

    if not stream_url:
        raise HTTPException(status_code=404, detail="No stream URL found")

    # Store in cache with 6 hours (21600 seconds) expiration window
    stream_cache[videoId] = (stream_url, now + STREAM_CACHE_TTL_SECONDS)

    return {"stream_url": stream_url}

