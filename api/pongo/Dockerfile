FROM python:3.15-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg curl unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# yt-dlp needs a JavaScript runtime to solve YouTube's challenges
RUN curl -fsSL https://deno.land/install.sh | DENO_INSTALL=/usr/local sh -s -- --no-modify-path

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

RUN useradd --create-home pongo && mkdir -p /data && chown pongo /data
USER pongo
# The self-updated yt-dlp lands in the user's site-packages
ENV PATH=/home/pongo/.local/bin:$PATH

ENTRYPOINT ["./entrypoint.sh"]
