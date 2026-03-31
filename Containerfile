# FreeSynergy packaging for Mistral.rs — LLM Inference Server
# Build: podman build -t ghcr.io/freesynergy/mistral:latest .
# Note: CPU-only build. For GPU support use feature flags (cuda, metal).
FROM docker.io/library/rust:1-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential clang libclang-dev cmake \
    libssl-dev pkg-config libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY . .
RUN cargo build --release \
    -p mistralrs-server \
    --features "accelerate"

FROM docker.io/library/debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates libssl3 libgomp1 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release/mistralrs-server /usr/local/bin/mistralrs-server

RUN useradd -r -s /bin/false mistral && \
    mkdir -p /etc/mistral /var/lib/mistral/models && \
    chown -R mistral:mistral /etc/mistral /var/lib/mistral

VOLUME ["/var/lib/mistral/models"]
EXPOSE 1234

USER mistral
ENTRYPOINT ["/usr/local/bin/mistralrs-server"]
CMD ["--port", "1234", "--model-dir", "/var/lib/mistral/models"]
