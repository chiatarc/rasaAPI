# Use official Rasa image as base builder
FROM rasa/rasa:3.6.21-full as builder

# Set working directory
WORKDIR /build

# Copy all files
COPY . /build/

# Create and activate virtual environment
RUN python -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir -U "pip==22.*" "wheel>0.38.0" && \
    poetry install --no-dev --no-root --no-interaction && \
    poetry build -f wheel -n && \
    pip install --no-deps dist/*.whl && \
    rm -rf dist *.egg-info

# Use a fresh base Rasa image for running the application
FROM rasa/rasa:3.6.21-full as runner

# Copy installed virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv

# Set environment variables
ENV PATH="/opt/venv/bin:$PATH"
ENV HOME=/app

# Set working directory
WORKDIR /app

# Update permissions and avoid running as root
RUN chgrp -R 0 /app && chmod -R g=u /app && chmod o+wr /app
USER 1001

# Expose Rasa API port
EXPOSE 5005

# Run Rasa
ENTRYPOINT ["rasa"]
CMD ["run", "--enable-api", "--cors", "*"]
