# CNI Node

[![License: Apache-2.0][Apache 2.0 Badge]][Apache 2.0]
[![GitHub Release Badge]][GitHub Releases]
[![Multus Badge]][Multus Release]
[![CNI Plugins Badge]][CNI Plugins Release]

A [Docker] image for installing and configuring [CNI Plugins] and [Multus CNI]
on a node. For example on a [Kubernetes] one.

## Usage

Run without arguments to see usage:

```
$ docker run --rm openvnf/cni-node
```

Print list of available CNI plugins:

```
$ docker run --rm openvnf/cni-node list
```

### Install CNI

The following components can be installed:

* CNI plugins binaries
* CNI configuration files
* Kubernetes objects for plugins support

#### Binaries

Plugins binaries are installed to the "/host/opt/cni/bin" directory:

```
$ docker run --rm \
    -v /opt/cni/bin:/host/opt/cni/bin \
    openvnf/cni-node install --plugins=flannel,ipvlan
```

Will install specified plugins to "/opt/cni/bin".

#### Configuration

CNI configuration files are installed to the "/host/etc/cni/net.d" directory,
and the specified templates will be looked up in the "/etc/cni/net.d" one:

```
$ docker run --rm \
    -v /etc/cni/net.d:/host/etc/cni/net.d \
    -v $PWD/multus.conf:/etc/cni/net.d/05-multus.conf \
    -v $PWD/ipvlan.conf:/etc/cni/net.d/10-ipvlan.conf \
    openvnf/cni-node install --configs=05-multus.conf,10-ipvlan.conf
```

Configuration template files might contain special pointers named after the
existing in the destination directory CNI configuration files. Each pointer will
be replaced by the corresponding file content in a final configuration file.

Thus, if "multus.conf" from the example above contains the following line:

```
__10-calico.conflist__
```

and a file with the name "10-calico.conflist" exists in "/etc/cni/net.d", then
content of this file will substitute the pointer in the final
"/etc/cni/net.d/05-multus.conf" file.

#### Kubernetes Objects

In order to support an installed CNI plugin, for example create a pod or a node
specific [ClusterRoleBinding], a Kubernetes object can be created from a
manifest. Manifests are expected in the "/etc/kubernetes/manifests" directory:

```
$ docker run --rm \
    -v $PWD:/etc/kubernetes/manifests \
    openvnf/cni-node install --manifests=crb.yaml,sa.yaml
```

Kubernetes objects will be created from the specified files if they exist in
"$PWD". If the files contain any environment variable references ("$VAR" or
"${VAR}") they will be substituted.

#### All Together

The options can be used togehter to install/uninstall plugins, configurations,
and create/delete Kubernetes objects in one run.

### Uninstall CNI

To delete installed plugins, configuration files or created Kubernetes objects,
use "uninstall" command in the examples above.

### Wait

To wait for a SIGINT or SIGTERM signal after install or uninstall action add
"--wait" option.

## Kubernetes Example

This example uses [DaemonSet] to install Multus and Macvlan CNI plugins on each
Kubernetes node and configure Multus CNI the way describing delegation to the
existing Calico configuration (assuming "/etc/cni/net.d/10-calico.conflist"
exists).

Use Multus CNI Node [Manifest] to create the example workloads:

```
$ kubectl create -f https://raw.githubusercontent.com/openvnf/cni-node/master/examples/multus-cni-node.yaml
```

After installation pods of the daemonset keep running (using "--wait" option)
and can be used to apply configuration changes. To change configuration edit
the ConfigMap:

```
$ kubectl -n kube-system edit configmap multus-cni-node-config
```

To apply the changes delete the "multus-cni-node" pods to make them restart:

```
$ kubectl -n kube-system delete po -l app=multus-cni-node
```

In this example deleting a multus-cni-node pod also causes uninstalling plugins
and configuration. See the "lifecycle" section of pod container.

Please note, this example does not create ready to use Multus CNI solution. It
just installs plugin binaries and configuration. For complete solution please
refer [Multus CNI] documentation (the hard way) or [Cennsonic Based] example
(the easy way).

## License

Copyright 2018 Travelping GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

<!-- Links -->

[Docker]: https://docs.docker.com
[Manifest]: examples/multus-cni-node.yaml
[DaemonSet]: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset
[Kubernetes]: https://kubernetes.io
[Multus CNI]: https://github.com/intel/multus-cni
[CNI Plugins]: https://github.com/containernetworking/plugins
[Cennsonic Based]: https://github.com/travelping/cennsonic/blob/master/docs/components/network.md#multus
[ClusterRoleBinding]: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding

<!-- Badges -->

[Apache 2.0]: https://opensource.org/licenses/Apache-2.0
[Apache 2.0 Badge]: https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg?style=flat-square
[GitHub Releases]: https://github.com/openvnf/cni-node/releases
[GitHub Release Badge]: https://img.shields.io/github/release/openvnf/cni-node/all.svg?style=flat-square
[Multus Badge]: https://img.shields.io/badge/Multus%20CNI-v3.1-green.svg?style=flat-square
[Multus Release]: https://github.com/intel/multus-cni/releases/tag/v3.1
[CNI Plugins Badge]: https://img.shields.io/badge/CNI%20Plugins-v0.7.4-green.svg?style=flat-square
[CNI Plugins Release]: https://github.com/containernetworking/plugins/releases/tag/v0.7.4
