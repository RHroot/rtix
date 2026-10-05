# This a guide to download and install models to run locally

### Shell with Huggingface

```bash
nix shell nixpkgs#python313Packages.huggingface-hub
```

### Download model

```bash
mkdir -pv ./models && hf download Qwen/Qwen2.5-3B-Instruct-GGUF qwen2.5-3b-instruct-q4_k_m.gguf --local-dir ./models/qwen
```

### Try to run llama.cpp

```bash
nix run --no-write-lock-file github:ggml-org/llama.cpp#cuda -- --help
```

### Verify if the gpu is working

```bash
nix run github:ggml-org/llama.cpp#cuda -- --list-devices
```

### Run llama.cpp

```bash
nix run github:ggml-org/llama.cpp#cuda -- \
  -m /path/to/qwen-model.gguf \
  --host 0.0.0.0 --port 8080 \
  -ngl 99 \
  --threads 6
```
