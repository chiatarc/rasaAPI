# Use official Rasa image as base
FROM rasa/rasa:3.6.21-full as builder

# Switch to root user to install packages
USER root

# Set working directory
WORKDIR /home/app

# Copy only necessary files first (improves caching)
COPY pyproject.toml poetry.lock /home/app/

# Ensure dependencies are up-to-date
RUN python -m pip install --no-cache-dir --upgrade pip setuptools wheel poetry packaging

# Create and activate a virtual environment inside the app directory
RUN python -m venv /home/app/venv && \
    /bin/bash -c "source /home/app/venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir poetry && \
    poetry config virtualenvs.create false && \
    poetry install --no-root --no-interaction --no-ansi"

# Copy the rest of the application code
COPY . /home/app/

# Use a fresh base Rasa image for running the application
FROM rasa/rasa:3.6.21-full as runner

# Set working directory
WORKDIR /home/app

# Copy installed dependencies and application files from builder stage
COPY --from=builder /home/app /home/app

# Set environment variables
ENV HOME=/home/app
ENV PATH="/home/app/venv/bin:$PATH"

# Ensure Rasa has execution permissions
RUN chmod +x /home/app/venv/bin/rasa

# Switch back to non-root user (recommended for security)
USER 1001

# Ensure the entrypoint is correct
ENTRYPOINT ["/home/app/venv/bin/rasa"]
CMD ["run", "--enable-api", "--cors", "*"]

# Expose Rasa API port
EXPOSE 5005
