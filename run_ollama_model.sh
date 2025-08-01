#!/bin/bash

export OLLAMA_MODELS="/data/ollama/models"

MODEL_NAME="hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF"
MODEL_PATTERN="UD-Q8_K_XL"

ollama run "$MODEL_NAME:$MODEL_PATTERN"
