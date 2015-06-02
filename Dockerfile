# Packer
FROM debian:jessie
MAINTAINER Kevin Littlejohn <kevin@littlejohn.id.au>

# apt-get and cleanup
RUN apt-get -yq update \
    && apt-get -yq install curl ca-certificates build-essential git mercurial \
      sudo vim zlib1g-dev libssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Environment variables in one hit
ENV PATH=$PATH:/usr/local/go/bin:/usr/local/gopath/bin:/usr/local/packer \
    GOPATH=/usr/local/gopath \
    PYTHON_VER=2.7.9 \
    HOME=/home/packer

# Install go, to compile packer and the plugins
RUN curl -L https://go.googlecode.com/files/go1.2.src.tar.gz | tar -v -C /usr/local -xz \
    && cd /usr/local/go/src \
    && ./make.bash --no-clean

RUN mkdir -p /usr/local/packer
RUN go get -u github.com/mitchellh/gox

# Install packer
RUN git clone https://github.com/mitchellh/packer.git $GOPATH/src/github.com/mitchellh/packer \
    && cd $GOPATH/src/github.com/mitchellh/packer \
    && make updatedeps \
    && make dev \
    # Install packer-windows-plugins
    && git clone https://github.com/packer-community/packer-windows-plugins.git $GOPATH/src/github.com/packer-community/packer-windows-plugin \
    && cd $GOPATH/src/github.com/packer-community/packer-windows-plugin \
    && make updatedeps \
    && make dev \
    # Copy all the binaries to /usr/local/packer
    && mkdir -p /usr/local/packer \
    && mv $GOPATH/bin/* /usr/local/packer/ \
    # Clean up
    && cd / \
    && rm -rf $GOPATH /usr/local/go

# Run as a user for security friendliness
RUN adduser --disabled-password --gecos "" packer; \
  echo "packer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER packer
WORKDIR /app

# Suggested running: docker run -it -e AWS_SECRET_KEY -e AWS_
ENTRYPOINT ["/usr/local/packer/packer"]
