FROM ubuntu:18.04

# this is a non-interactive automated build - avoid some warning messages
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update 
RUN apt-get install -y --no-install-recommends \
        bzip2 \
        curl \
        git \
        unzip \
        wget \
        xz-utils

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN \
        { \
                echo '#!/bin/sh'; \
                echo 'set -e'; \
                echo; \
                echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
        } > /usr/local/bin/docker-java-home \
        && chmod +x /usr/local/bin/docker-java-home

# do some fancy footwork to create a JAVA_HOME that's cross-architecture-safe
RUN ln -svT "/usr/lib/jvm/java-8-openjdk-$(dpkg --print-architecture)" /docker-java-home
ENV JAVA_HOME /docker-java-home

RUN set -ex; \
        # deal with slim variants not having man page directories (which causes "update-alternatives" to fail)
        if [ ! -d /usr/share/man/man1 ]; then \
                mkdir -p /usr/share/man/man1; \
        fi; \
        apt-get install -y --no-install-recommends openjdk-8-jdk; \
        # verify that "docker-java-home" returns what we expect
        [ "$(readlink -f "$JAVA_HOME")" = "$(docker-java-home)" ]; \
        # update-alternatives so that future installs of other OpenJDK versions don't change /usr/bin/java
        update-alternatives --get-selections | awk -v home="$(readlink -f "$JAVA_HOME")" 'index($3, home) == 1 { $2 = "manual"; print | "update-alternatives --set-selections" }'; \
        # ... and verify that it actually worked for one of the alternatives we care about
        update-alternatives --query java | grep -q 'Status: manual'

RUN rm -rf /var/lib/apt/lists/* && apt-get clean

# install maven
ENV MAVEN_HOME /opt/maven
ENV MAVEN_VERSION 3.6.0
ENV maven_archive apache-maven-${MAVEN_VERSION}-bin.tar.gz
RUN wget -O /tmp/$maven_archive https://www-eu.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/$maven_archive
RUN tar xzf /tmp/$maven_archive -C /opt/ && rm -f /tmp/$maven_archive
RUN ln -s /opt/apache-maven-${MAVEN_VERSION} $MAVEN_HOME
RUN ln -s $MAVEN_HOME/bin/mvn /usr/local/bin

# install gradle
ENV GRADLE_HOME /opt/gradle
ENV GRADLE_VERSION 5.3.1
ENV gradle_archive gradle-${GRADLE_VERSION}-bin.zip
RUN wget -O /tmp/$gradle_archive https://services.gradle.org/distributions/$gradle_archive
RUN unzip /tmp/$gradle_archive && rm -f /tmp/$gradle_archive
RUN mv gradle-${GRADLE_VERSION} ${GRADLE_HOME}/
RUN ln --symbolic ${GRADLE_HOME}/bin/gradle /usr/bin/gradle
RUN gradle -v
