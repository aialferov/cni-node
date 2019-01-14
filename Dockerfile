ARG KUBE_WATCH_VERSION=0.3.0
FROM quay.io/travelping/kube-watch:${KUBE_WATCH_VERSION}

ARG PROJECT=
ARG VERSION=
ARG GIT_SHA=

LABEL PROJECT="${PROJECT}"

ARG MULTUS_CNI_VERSION=v3.1
ARG CNI_PLUGINS_VERSION=v0.7.4

ARG MULTUS_CNI_URL=\
https://github.com/intel/multus-cni/releases/download/\
${MULTUS_CNI_VERSION}/multus-cni_${MULTUS_CNI_VERSION}_linux_amd64.tar.gz

ARG CNI_PLUGINS_URL=\
https://github.com/containernetworking/plugins/releases/download/\
${CNI_PLUGINS_VERSION}/cni-plugins-amd64-${CNI_PLUGINS_VERSION}.tgz

RUN apk upgrade --no-cache --update && \
    apk add --no-cache gettext && \
    mkdir -p /opt/cni/bin && \
    wget -O- "${CNI_PLUGINS_URL}" | tar -C /opt/cni/bin -xz && \
    wget -O- "${MULTUS_CNI_URL}" | tar -C /opt/cni/bin -xz --strip 1 && \
    rm /opt/cni/bin/README.md && \
    rm /opt/cni/bin/LICENSE && \
    echo "${VERSION} (git-${GIT_SHA})" > "/${PROJECT}-version"

COPY src /bin
ENTRYPOINT ["/bin/cni-node"]
