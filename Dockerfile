# Use official Rasa image as base
FROM rasa/rasa:3.6.21-full as builder

# Set working directory
WORKDIR /home/app

# Copy all files
COPY . /home/app/

# Install dependencies globally
RUN pip install --no-cache-dir --upgrade pip "wheel>0.38.0" && \
    pip install --no-cache-dir poetry && \
    poetry install --no-root --no-interaction && \
    poetry build -f wheel -n && \
    pip install --no-deps dist/*.whl && \
    rm -rf dist *.egg-info

# Use a fresh base Rasa image for running the application
FROM rasa/rasa:3.6.21-full as runner

# Set working directory
WORKDIR /home/app

# Copy installed dependencies from builder stage
COPY --from=builder /home/app /home/app

# Set environment variables
ENV HOME=/home/app
ENV PATH="/home/app/.local/bin:$PATH"

# Expose Rasa API port
EXPOSE 5005

# **Use absolute path for entrypoint**
ENTRYPOINT ["/usr/local/bin/rasa"]
CMD ["run", "--enable-api", "--cors", "*"]
