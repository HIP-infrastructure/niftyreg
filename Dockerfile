ARG CI_REGISTRY_IMAGE
ARG TAG
ARG DOCKERFS_TYPE
ARG DOCKERFS_VERSION
ARG JUPYTERLAB_DESKTOP_VERSION
FROM ${CI_REGISTRY_IMAGE}/${DOCKERFS_TYPE}:${DOCKERFS_VERSION}${TAG}
LABEL maintainer="florian.sipp@chuv.ch"

ARG DEBIAN_FRONTEND=noninteractive
ARG CARD
ARG CI_REGISTRY
ARG APP_NAME
ARG APP_VERSION

LABEL app_version=$APP_VERSION
LABEL app_tag=$TAG

WORKDIR /apps/${APP_NAME}

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \ 
    git cmake build-essential libgomp1

RUN git clone https://github.com/KCL-BMEIS/niftyreg niftyreg-git
ADD "https://api.github.com/repos/KCL-BMEIS/niftyreg/commits?sha=master&per_page=1" niftyreg_latest_commit

RUN mkdir build && \
    cd build && \
    cmake ../niftyreg-git -Wno-dev -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make -j7 && \
    make install && \
    cd .. && \
    rm -rf build && \
    rm -rf niftyreg-git && \
    apt-get remove -y --purge git cmake build-essential && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV APP_SPECIAL="terminal"
ENV APP_CMD=""
ENV PROCESS_NAME=""
ENV APP_DATA_DIR_ARRAY=""
ENV DATA_DIR_ARRAY=""

HEALTHCHECK --interval=10s --timeout=10s --retries=5 --start-period=30s \
  CMD sh -c "/apps/${APP_NAME}/scripts/process-healthcheck.sh \
  && /apps/${APP_NAME}/scripts/ls-healthcheck.sh /home/${HIP_USER}/nextcloud/"

COPY ./scripts/ scripts/

ENTRYPOINT ["./scripts/docker-entrypoint.sh"]
