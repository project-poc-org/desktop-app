# Multi-stage build for Python desktop app
# Note: This is for containerized testing/CI purposes
# Desktop GUI apps typically aren't deployed in containers for production
FROM python:3.11-slim AS builder

# Set working directory
WORKDIR /app

# Install build dependencies including tkinter
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-tk \
    tk-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements (currently empty, but may have future deps)
COPY requirements.txt .
RUN mkdir -p /root/.local && \
    if [ -s requirements.txt ]; then pip install --no-cache-dir --user -r requirements.txt; fi

# Final stage
FROM python:3.11-slim

# Install runtime dependencies for tkinter and X11
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-tk \
    x11-apps \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -u 1000 -s /bin/bash appuser

# Copy installed packages from builder (will be empty if no requirements)
COPY --from=builder --chown=appuser:appuser /root/.local /home/appuser/.local

# Set working directory
WORKDIR /app

# Copy application code (explicit files/dirs to avoid sensitive data)
COPY --chown=appuser:appuser --chmod=755 app/ ./app/
COPY --chown=appuser:appuser --chmod=644 app.py ./


# Update PATH to include user-installed packages
ENV PATH=/home/appuser/.local/bin:$PATH

# Set display environment variable for X11
ENV DISPLAY=:0

# Switch to non-root user
USER appuser

# Health check (basic Python import check)
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python -c "import tkinter; print('OK')"

# Run application (requires X11 forwarding)
CMD ["python", "app.py"]
