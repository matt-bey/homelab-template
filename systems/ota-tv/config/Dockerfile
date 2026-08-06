# hdhomerun_config (the control-protocol CLI) ships in the Debian
# "hdhomerun-config" package. We use the control protocol, not the HTTP JSON
# API, because only it can tune an idle tuner to a chosen RF channel and read
# ss/snq/seq without opening a video stream. See probe.py header for the full
# rationale.
FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends hdhomerun-config \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir prometheus-client==0.21.1

WORKDIR /app
COPY probe.py /app/probe.py

# -u: unbuffered stdout so `docker logs` shows each sweep immediately.
CMD ["python", "-u", "probe.py"]
