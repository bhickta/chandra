#!/usr/bin/env bash
set -e

# Start the vLLM server with 4-bit quantization (bitsandbytes)
echo "Starting Chandra vLLM server with 4-bit quantization..."
uv run chandra_vllm --quantization bitsandbytes
