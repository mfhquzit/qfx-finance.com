# Dockerfile for QFX Finance

# Use the official PostgreSQL image
FROM postgres:latest

# Set environment variables
ENV POSTGRES_DB=qfx_finance
ENV POSTGRES_USER=user
ENV POSTGRES_PASSWORD=securepassword

# Expose the port
EXPOSE 5432

# Keep the container running
CMD ["postgres"]
