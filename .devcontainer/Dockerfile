FROM ubuntu:22.04

# Update package list and install curl only (explicitly avoid wget)
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get remove -y wget || true && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash vscode
USER vscode
WORKDIR /home/vscode

# Verify curl is available and wget is not
RUN curl --version
RUN ! command -v wget
