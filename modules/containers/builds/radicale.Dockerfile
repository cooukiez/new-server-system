# https://github.com/Kozea/Radicale/blob/17e461cd828eea7013a41a727be90fbf030871d0/Dockerfile

FROM python:3-alpine AS builder

ARG VERSION=master
ARG DEPENDENCIES

RUN apk add --no-cache --virtual gcc libffi-dev musl-dev \
    && python -m venv /app/venv \
    && /app/venv/bin/pip install --no-cache-dir "Radicale[${DEPENDENCIES}] @ https://github.com/Kozea/Radicale/archive/${VERSION}.tar.gz"

FROM python:3-alpine

WORKDIR /app

RUN addgroup -g 1000 radicale \
    && adduser radicale --home /var/lib/radicale --system --uid 1000 --disabled-password -G radicale \
    && apk add --no-cache ca-certificates openssl curl git

COPY --chown=radicale:radicale --from=builder /app/venv /app

VOLUME /var/lib/radicale

ENTRYPOINT [ "/app/bin/python", "/app/bin/radicale"]
CMD ["--hosts", "0.0.0.0:5232,[::]:5232"]

USER radicale