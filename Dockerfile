FROM openjdk:8-jdk-slim

ENV OPENCB_HOME=/opt/opencb \
    OPENCGA_HOME=/opt/opencga \
    JAVA_OPTS="-Xmx4g -Xms4g" \
    PATH="${OPENCGA_HOME}/bin:${PATH}"

RUN apt-get update && apt-get install -y \
    maven \
    git \
    curl \
    netcat \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${OPENCB_HOME} ${OPENCGA_HOME}

WORKDIR ${OPENCB_HOME}

# Copy scripts and config
COPY entrypoint.sh /usr/local/bin/
COPY config/ /root/.m2/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Build Phase 1: Dependencies
RUN git clone -b develop https://github.com/opencb/java-common-libs.git && \
    cd java-common-libs && mvn clean install -DskipTests -q && cd ..

RUN git clone -b develop https://github.com/opencb/biodata.git && \
    cd biodata && mvn clean install -DskipTests -q && cd ..

RUN git clone -b develop https://github.com/opencb/datastore.git && \
    cd datastore && mvn clean install -DskipTests -q && cd ..

RUN git clone -b develop https://github.com/opencb/cellbase.git && \
    cd cellbase && mvn clean install -DskipTests -q && cd ..

# Build Phase 2: OpenCGA
RUN git clone -b develop https://github.com/opencb/opencga.git && \
    cd opencga && mvn clean install -DskipTests -q && \
    cp -r build/* ${OPENCGA_HOME}/ && cd ..

RUN mkdir -p ${OPENCGA_HOME}/logs && chmod -R 755 ${OPENCGA_HOME}/bin

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
