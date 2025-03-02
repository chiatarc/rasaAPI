# Use official Rasa image as base builder
FROM rasa/rasa:3.6.21-full as builder

# Create a writable working directory
WORKDIR /home/app

# Copy all files
COPY . /home/app/

# Set user early to avoid permission issues
USER root

# Install dependencies globally (no virtualenv needed)
RUN pip install --no-cache-dir --upgrade pip "wheel>0.38.0" && \
    pip install --no-cache-dir poetry && \
    poetry install --no-root --no-interaction && \
    poetry build -f wheel -n && \
    pip install --no-deps dist/*.whl && \
    rm -rf dist *.egg-info

# Use a fresh base Rasa image for running the application
FROM rasa/rasa:3.6.21-full as runner

# Copy installed dependencies from builder stage
COPY --from=builder /home/app /home/app

# Set environment variables
ENV HOME=/home/app

# Set working directory
WORKDIR /home/app

# Expose Rasa API port
EXPOSE 5005

# Run Rasa
ENTRYPOINT ["rasa"]
CMD ["run", "--enable-api", "--cors", "*"]
