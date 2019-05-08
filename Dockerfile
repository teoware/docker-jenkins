FROM jenkins/jenkins

# Build args
ARG MAVEN_VERSION="3.6.1"
ARG NODE_VERSION="10.x"
ARG DOCKER_COMPOSE_VERSION="1.24.0"

# Environment variables
ENV MAVEN_HOME "/opt/maven/default"
ENV M2_HOME "${MAVEN_HOME}"
ENV PATH "${PATH}:${MAVEN_HOME}/bin"

# Run the following commands as root
USER root

# Install packages
RUN apt-get update && \
    apt-get -y install apt-transport-https \
                       software-properties-common \
                       gnupg2 \
                       apt-utils

# Install Apache Maven
RUN curl -fsSL "https://www.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
         -o /tmp/maven.tar.gz && \
    curl -fsSL "https://www.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz.asc" \
         -o /tmp/maven.tar.gz.asc && \
    curl -fsSL "https://www.apache.org/dist/maven/KEYS" \
         -o /tmp/maven.KEYS && \
    gpg --import /tmp/maven.KEYS && \
    gpg --verify /tmp/maven.tar.gz.asc /tmp/maven.tar.gz && \
    mkdir /opt/maven && \
    tar -xzvf /tmp/maven.tar.gz -C /opt/maven/ && \
    cd /opt/maven && \
    ln -s apache-maven-${MAVEN_VERSION}/ default && \
    rm -f /tmp/maven.* && \
    update-alternatives --install "/usr/bin/mvn" "mvn" "/opt/maven/default/bin/mvn" 1 && \
    update-alternatives --set "mvn" "/opt/maven/default/bin/mvn"

# Install NodeJS
RUN RELEASE="$(lsb_release -cs)" && \
    curl -fsSL "https://deb.nodesource.com/gpgkey/nodesource.gpg.key" | apt-key add - && \
    echo "deb https://deb.nodesource.com/node_${NODE_VERSION} ${RELEASE} main" > /etc/apt/sources.list.d/node.list && \
    echo "deb-src https://deb.nodesource.com/node_${NODE_VERSION} ${RELEASE} main" >> /etc/apt/sources.list.d/node.list && \
    apt-get update && \
    apt-get -y install nodejs

# Install Docker
RUN DISTRO="$(. /etc/os-release; echo ${ID})" && \
    RELEASE="$(lsb_release -cs)" && \
    curl -fsSL "https://download.docker.com/linux/${DISTRO}/gpg" | apt-key add - && \
    echo "deb [arch=amd64] https://download.docker.com/linux/${DISTRO} ${RELEASE} stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get -y install docker-ce

# Install Docker Compose
RUN curl -fsSL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
         -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Add jenkins user to docker group
RUN usermod -a -G docker jenkins

# Change back to application user
USER jenkins
