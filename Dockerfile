# Base image for the runner
FROM ubuntu:24.10

# Runner version to be used.
ARG RUNNER_VERSION="2.322.0"

# Accept default answers for all commands
ENV DEBIAN_FRONTEND=noninteractive

# Required Environment variables
ENV GH_ORG=""
ENV GH_RUNNER_NAME_PATTERN=""
ENV GH_TOKEN=""
ENV GH_LABELS=""

# Update and upgrade repositories and create user docker
RUN apt update -y && \
  apt upgrade -y && \
  useradd -m docker

# Install required packages
RUN apt install -y --no-install-recommends \
  curl \
  wget \
  zip \
  unzip \
  git \
  jq \
  build-essential \
  libssl-dev \
  libffi-dev \
  libicu-dev \
  apt-transport-https \
  ca-certificates \
  gnupg

# Installing kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Installing OpenTofu
RUN install -m 0755 -d /etc/apt/keyrings && \
  curl -fsSL https://get.opentofu.org/opentofu.gpg | tee /etc/apt/keyrings/opentofu.gpg >/dev/null && \
  curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg >/dev/null && \
  chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg && \
  echo \
  "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main \
  deb-src [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" | \
  tee /etc/apt/sources.list.d/opentofu.list > /dev/null \
  chmod a+r /etc/apt/sources.list.d/opentofu.list && \
  apt update && \
  apt install -y tofu

# Download the runner package and extract it
RUN cd /home/docker && mkdir actions-runner && cd actions-runner && \
  curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
  tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Make docker user the owner of all runner files
RUN chown -R docker ~docker && \
  /home/docker/actions-runner/bin/installdependencies.sh

# Copy the docker entrypoint script and assign it execution permission
COPY docker-entrypoint.sh .
RUN chmod +x docker-entrypoint.sh

# Switch to the docker user
USER docker

# Entrypoint for the image
ENTRYPOINT [ "./docker-entrypoint.sh" ]
