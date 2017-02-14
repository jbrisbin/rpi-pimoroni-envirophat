FROM resin/rpi-raspbian:jessie
MAINTAINER Jon Brisbin <jon@jbrisbin.com>

# Update APT cache
RUN apt-get update

# Install Python 3
RUN apt-get install -y \
    python3 \
    python3-dev \
    python3-pip \
    python3-virtualenv \
    --no-install-recommends

# Install kernel utils to read I2C data
RUN apt-get install -y \
    libffi-dev \
    i2c-tools \
    libraspberrypi-bin \
    --no-install-recommends

# Install smbus and envirophat tools
RUN apt-get install -y \
    python3-smbus \
    python3-envirophat \
    --no-install-recommends

# Clean up APT cache
RUN rm -rf /var/lib/apt/lists/*

VOLUME /data
WORKDIR /data

# Set CMD to python3
ENTRYPOINT ["python3"]