FROM alpine

ARG PROJECT=
ARG VERSION=
ARG GIT_SHA=

LABEL PROJECT="${PROJECT}"

ARG MULTUS_CNI_VERSION=v3.1
ARG CNI_PLUGINS_VERSION=v0.7.4
ARG KUBECTL_VERSION=v1.12.1

ARG MULTUS_CNI_URL=\
https://github.com/intel/multus-cni/releases/download/\
${MULTUS_CNI_VERSION}/multus-cni_${MULTUS_CNI_VERSION}_linux_amd64.tar.gz

ARG CNI_PLUGINS_URL=\
https://github.com/containernetworking/plugins/releases/download/\
${CNI_PLUGINS_VERSION}/cni-plugins-amd64-${CNI_PLUGINS_VERSION}.tgz

ARG KUBECTL_URL=\
https://storage.googleapis.com/kubernetes-release/release/\
${KUBECTL_VERSION}/bin/linux/amd64/kubectl

RUN apk upgrade --no-cache --update && \
    apk add --no-cache gettext && \
    mkdir -p /opt/cni/bin && \
    wget -O- "${CNI_PLUGINS_URL}" | tar -C /opt/cni/bin -xz && \
    wget -O- "${MULTUS_CNI_URL}" | tar -C /opt/cni/bin -xz --strip 1 && \
    wget -O- "${KUBECTL_URL}" | tee /bin/kubectl > /dev/null && \
    rm /opt/cni/bin/README.md && \
    rm /opt/cni/bin/LICENSE && \
    chmod +x /bin/kubectl && \
    echo "${VERSION} (git-${GIT_SHA})" > /version

COPY src /bin
ENTRYPOINT ["/bin/cni-node"]
