# FreeSynergy packaging for mistral.rs (local LLM inference)
# Build: podman build -t ghcr.io/freesynergy/mistral:latest .
FROM docker.io/library/rust:1-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential clang libclang-dev cmake libssl-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY . .
RUN cargo build --release \
    -p mistralrs-cli \
    --no-default-features \
    --features "cuda-12-0,flash-attn,cudnn"

FROM docker.io/nvidia/cuda:12.0.0-runtime-ubuntu22.04
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates libssl3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release/mistralrs /usr/local/bin/mistralrs

EXPOSE 1234
ENTRYPOINT ["/usr/local/bin/mistralrs"]
CMD ["server", "--host", "0.0.0.0", "--port", "1234"]
