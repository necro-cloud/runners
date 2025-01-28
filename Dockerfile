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

# NVM Variables
# ENV NVM_DIR /usr/local/nvim
# ENV NODE_VERSION v23.6.1

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
  gnupg \
  openjdk-21-jdk

# Installing NodeJS
# RUN mkdir -p ${NVM_DIR} && \
#   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
#   /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use --delete-prefix $NODE_VERSION"
#
# ENV NODE_PATH $NVM_DIR/versions/node/${NODE_VERSION}/bin
# ENV PATH      $NODE_PATH:$PATH
#
# RUN node --version

# Installing kubectl
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
  chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list && \
  chmod 644 /etc/apt/sources.list.d/kubernetes.list && \
  apt update && \
  apt install -y kubectl

# Installing the CNPG Plugin
RUN wget https://github.com/cloudnative-pg/cloudnative-pg/releases/download/v1.25.0/kubectl-cnpg_1.25.0_linux_x86_64.deb  && \
  dpkg -i kubectl-cnpg_1.25.0_linux_x86_64.deb

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

# Installing MinIO CLI
RUN curl https://dl.min.io/client/mc/release/linux-amd64/mc \
  -o /usr/local/bin/mc && \
  chmod +x /usr/local/bin/mc

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
