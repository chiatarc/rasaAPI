# Use official Rasa image as base builder
FROM rasa/rasa:3.6.21-full as builder

# Create a writable working directory
WORKDIR /home/app

# Copy all files
COPY . /home/app/

# Set user early to avoid permission issues
USER root

# Install dependencies inside a dedicated virtual environment
RUN python -m venv /home/app/venv && \
    . /home/app/venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip "wheel>0.38.0" && \
    pip install --no-cache-dir poetry && \
    poetry install --no-dev --no-root --no-interaction && \
    poetry build -f wheel -n && \
    pip install --no-deps dist/*.whl && \
    rm -rf dist *.egg-info

# Use a fresh base Rasa image for running the application
FROM rasa/rasa:3.6.21-full as runner

# Copy installed virtual environment from builder stage
COPY --from=builder /home/app/venv /home/app/venv

# Set environment variables
ENV PATH="/home/app/venv/bin:$PATH"
ENV HOME=/home/app

# Set working directory
WORKDIR /home/app

# Expose Rasa API port
EXPOSE 5005

# Run Rasa
ENTRYPOINT ["rasa"]
CMD ["run", "--enable-api", "--cors", "*"]
