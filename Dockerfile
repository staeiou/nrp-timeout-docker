FROM nvidia/cuda:12.9.1-runtime-ubuntu22.04

SHELL ["/bin/bash", "-lc"]
ENV DEBIAN_FRONTEND=noninteractive


# --------------------------------------------------------------------
# System deps + Python + Node (no conda, no nvm)
# --------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 python3-venv python3-dev python3-pip \
      build-essential git curl wget cmake jq tini \
      libcurl4-openssl-dev ca-certificates gnupg \
      net-tools less zip nano tmux htop nvtop iotop jnettop pciutils \
      libgomp1 libnuma1 libstdc++6 && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# --------------------------------------------------------------------
# Install uv globally
# --------------------------------------------------------------------
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    install -m 0755 /root/.local/bin/uv /usr/local/bin/uv && \
    rm -f /root/.local/bin/uv

# --------------------------------------------------------------------
# Single venv in /opt
# --------------------------------------------------------------------
RUN uv venv /opt/venv
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:${PATH}"
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PYTHONDONTWRITEBYTECODE=1

# --------------------------------------------------------------------
# Versions
# --------------------------------------------------------------------
ARG TORCH_VERSION=2.9.0
ARG TORCHVISION_VERSION=0.24.0
ARG TORCHAUDIO_VERSION=2.9.0
ARG VLLM_VERSION=0.13.0
ARG UNSLOTH_VERSION=2025.12.9
ARG UNSLOTH_ZOO_VERSION=2025.12.7

# --------------------------------------------------------------------
# ONE big install, but with PyPI as primary index
# --------------------------------------------------------------------
RUN uv pip install --no-cache-dir --upgrade --force-reinstall \
      --index-url https://pypi.org/simple \
      --index-strategy unsafe-best-match \
      --extra-index-url https://download.pytorch.org/whl/cu129 \
      "torch==${TORCH_VERSION}+cu129" \
      "torchvision==${TORCHVISION_VERSION}+cu129" \
      "torchaudio==${TORCHAUDIO_VERSION}+cu129" \
      "vllm==${VLLM_VERSION}" \
      "unsloth==${UNSLOTH_VERSION}" \
      "unsloth-zoo==${UNSLOTH_ZOO_VERSION}" \
      openai openai_harmony \
      torch-c-dlpack-ext litellm "lm_eval[hf,vllm,api]" \
      trl datasets transformers gguf sentencepiece mistral_common tf-keras \
      "httpx>=0.24.0" \
      "aiometer>=0.5.0" \
      "aiosqlite>=0.19.0" \
      "jmespath>=1.0.0" \
      "tenacity>=8.2.0" \
      "tqdm>=4.65.0" \
      "pandas>=2.0.0" \
      "openpyxl>=3.1.0" \
      "pyarrow>=12.0.0" \
      "py-mini-racer>=0.6.0"


# --------------------------------------------------------------------
# Pod timeout tracker for bash prompt
# --------------------------------------------------------------------
COPY pod-timeout-prompt.sh /usr/local/bin/pod-timeout-prompt.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/pod-timeout-prompt.sh /usr/local/bin/entrypoint.sh && \
    echo 'source /usr/local/bin/pod-timeout-prompt.sh' >> /root/.bashrc

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
