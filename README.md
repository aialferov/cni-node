# CNI Node

[![License: Apache-2.0][Apache 2.0 Badge]][Apache 2.0]
[![GitHub Release Badge]][GitHub Releases]
[![Multus Badge]][Multus Release]
[![CNI Plugins Badge]][CNI Plugins Release]

A [Docker] image for installing and configuring [CNI Plugins] and [Multus CNI]
on a node. For example on a [Kubernetes] one.

* [Usage](#usage)
  * [Install CNI](#install-cni)
    * [Binaries](#binaries)
    * [Configuration](#configuration)
    * [Kubernetes Objects](#kubernetes-objects)
    * [All Together](#all-together)
  * [Apply CNI](#apply-cni)
  * [Uninstall CNI](#uninstall-cni)
  * [Pause](#pause)
* [Usage in Kubernetes](#usage-in-kubernetes)
  * [Simple Example](#simple-example)
  * [Watching Changes](#watching-changes)
* [License](#license)

## Usage

Run without arguments to see usage:

```
$ docker run --rm quay.io/openvnf/cni-node
```

Print list of available CNI plugins:

```
$ docker run --rm quay.io/openvnf/cni-node list
```

### Install CNI

The following components can be installed:

* CNI plugins binaries
* CNI configuration files
* Kubernetes objects for plugins support.

#### Binaries

CNI plugins binaries are baked into the image and installed to the
"/host/opt/cni/bin" directory:

```
$ docker run --rm \
    -v /opt/cni/bin:/host/opt/cni/bin \
    quay.io/openvnf/cni-node install --plugins=flannel,ipvlan
```

Will install specified plugins to "/opt/cni/bin".

#### Configuration

CNI plugins configuration files (templates) should be mounted to the
"/etc/cni/net.d" directory and will be installed to the "/host/etc/cni/net.d"
directory (should be mounted from the node if you expect the files there):

```
$ docker run --rm \
    -v /etc/cni/net.d:/host/etc/cni/net.d \
    -v $PWD/multus.conf:/etc/cni/net.d/05-multus.conf \
    -v $PWD/ipvlan.conf:/etc/cni/net.d/10-ipvlan.conf \
    quay.io/openvnf/cni-node install --configs=05-multus.conf,10-ipvlan.conf
```

Configuration files might be templates containing special pointers named after
the existing in the destination directory CNI configuration files. Each pointer
will be replaced by the corresponding file content in the final configuration
file.

Thus, if "multus.conf" from the example above contains the following line:

```
__10-calico.conflist__
```

and a file with the name "10-calico.conflist" exists in "/host/etc/cni/net.d",
then content of this file will substitute the pointer in the final
"/host/etc/cni/net.d/05-multus.conf" file.

#### Kubernetes Objects

In order to support an installed CNI plugin, for example create a pod or a node
specific [ClusterRoleBinding], a Kubernetes object can be created from a
manifest. Manifests are expected to be in the "/etc/kubernetes/manifests"
directory:

```
$ docker run --rm \
    -v $PWD:/etc/kubernetes/manifests \
    quay.io/openvnf/cni-node install --manifests=crb.yaml,sa.yaml
```

In this example "$PWD" should contain specified manifest files.

If manifests contain any environment variable references ("$VAR" or "${VAR}")
they will be substituted by the corresponding value prior to an object creation.
Of course, these environment variables should be exported in the container.

Please note: this particular example most probably will not work "as is",
as Kubernetes API access is required. This requirement is usually satisfied when
container runs in a Kubernetes pod and has a corresponding service account
relation.

#### All Together

The options can be used togehter to install/uninstall plugins, configurations,
and create/delete Kubernetes objects in one run.

### Apply CNI

You can provide the desired and the current state of plugins, configurations or
manifests and the corresponding installation or uninstallation will happen. For
example if the currently installed set of CNI plugins is:

```
host-device,multus-cni,ipvlan
```

and the desired one is:

```
multus-cni,macvlan
```

you can apply it this way:

```
$ docker run --rm \
    -v /opt/cni/bin:/host/opt/cni/bin \
    quay.io/openvnf/cni-node apply \
        --plugins=multus-cni,macvlan:host-device,multus-cni,ipvlan
```

then the "multus-cni" plugin is not touched, but "ipvlan" and "host-device" are
removed and "macvlan" is installed.

### Uninstall CNI

To delete installed plugins, configuration files or created Kubernetes objects,
use "uninstall" command in the examples above. The assets will be deleted in
reverse of the specified order.

### Pause

To pause waiting for a SIGINT or SIGTERM signal after any action
(install/uninstall/apply) add "--pause" option.

## Usage in Kubernetes

One of the advantages in using CNI Node with Kubernetes is ability to
incorporate the [Kube Watch] project for tracking changes automatically applying
them. We will start from a simple example and get back to the Kube Watch based
one later on.

### Simple Example

This example uses [DaemonSet] to install Multus and Macvlan CNI plugins on each
Kubernetes node and configure Multus CNI the way describing delegation to the
existing Calico configuration, assuming "/etc/cni/net.d/10-calico.conflist"
exists on each node.

Use Multus CNI Node [Multus CNI Simple Manifest] to create the example
workloads:

```
$ kubectl apply -f https://raw.githubusercontent.com/openvnf/cni-node/master/manifests/multus-cni-simple.yaml
```

After installation pods of the daemonset keep running (using the "--pause"
option) and can be used to apply configuration changes. For example change set
of CNI plugins to install. To change configuration edit the ConfigMap:

```
$ kubectl -n kube-system edit configmap multus-cni-configs
```

To apply the changes delete the "multus-cni-node" pods to make them restart:

```
$ kubectl -n kube-system delete pods -l app=multus-cni-node
```

In this example deleting the "multus-cni-node" pods also causes plugins and
configuration uninstallation. See the "lifecycle" section of pod container in
the manifest.

Please note, this example does not create ready to use Multus CNI solution. It
just installs plugins binaries and configuration. The [Watching Changes](#watching-changes)
example implements ready to use solution.

Uninstall the example workloads:

```
$ kubectl delete -f https://raw.githubusercontent.com/openvnf/cni-node/master/manifests/multus-cni-simple.yaml
```

### Watching Changes

The example above requires pods restart on every configuration change. Also, in
this particular example if the Calico configuration file is updated the depended
Multus CNI configuration should also be updated. Of course, restart of such a
pod will trigger re-installation of everything, probably because of one part
change only.

The [CNI Node Docker Image] is based on the [Kube Watch] one, meaning can take
advantage of Kube Watch functionality. In this example we use it to watch
changes and perform automatic updates.

This example is also based on [DaemonSet] describing four containers. Each
container runs Kube Watch to follow the corresponding changes. Three of them
watch for "multus-cni" configmap changes to update set of plugins, plugin
configurations and manifests. The fourth one is watching for Calico config
changes to update the depended Multus CNI config. Thus, restart of pods is not
needed to apply the changes.

In this example we mount "kubectl" binary from a node as CNI Node uses it to
create or delete manifests, and Kube Watch requires it to watch the ConfigMap.
For the same purpose we create some [RBAC] objects.

Before deploying the example, please make sure you have uninstalled the [Simple
Example](#simple-example) related workloads if you played with it. It uses the
same naming and might make undesired impact.

To deploy this example we use the following manifests:

* [Multus CNI Config Manifest]
* [Multus CNI RBAC Manifest]
* [Multus CNI Manifest]

The Multus CNI Manifest should be deployed last:

```
$ kubectl apply -f https://raw.githubusercontent.com/openvnf/cni-node/master/manifests/multus-cni-config.yaml
$ kubectl apply -f https://raw.githubusercontent.com/openvnf/cni-node/master/manifests/multus-cni-rbac.yaml
$ kubectl apply -f https://raw.githubusercontent.com/openvnf/cni-node/master/manifests/multus-cni.yaml
```

You can try to edit the "multus-cni" ConfigMap or the "10-calico.conflist" file
to see how the changes get automatically applied.

During the example uninstallation the Multus CNI Manifest should be deleted
first:

```
$ kubectl delete -f https://raw.githubusercontent.com/openvnf/cni-node/master/manifests/multus-cni.yaml
$ kubectl delete -f https://raw.githubusercontent.com/openvnf/cni-node/master/manifests/multus-cni-rbac.yaml
$ kubectl delete -f https://raw.githubusercontent.com/openvnf/cni-node/master/manifests/multus-cni-config.yaml
```

See also:

* [Multus CNI Official →]
* [Multus CNI in Cennsonic →]

## License

Copyright 2018—2019 Travelping GmbH

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

[RBAC]: https://kubernetes.io/docs/reference/access-authn-authz/rbac
[Docker]: https://docs.docker.com
[DaemonSet]: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset
[Kubernetes]: https://kubernetes.io
[Kube Watch]: https://github.com/travelping/kube-watch
[Multus CNI]: https://github.com/intel/multus-cni
[CNI Plugins]: https://github.com/containernetworking/plugins
[ClusterRoleBinding]: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding

[CNI Node Docker Image]: Dockerfile
[Multus CNI Simple Manifest]: manifests/multus-cni-simple.yaml
[Multus CNI Manifest]: manifests/multus-cni.yaml
[Multus CNI RBAC Manifest]: manifests/multus-cni-rbac.yaml
[Multus CNI Config Manifest]: manifests/multus-cni-config.yaml

[Multus CNI Official →]: https://github.com/intel/multus-cni/blob/master/doc/quickstart.md
[Multus CNI in Cennsonic →]: https://github.com/travelping/cennsonic/blob/master/docs/components/network.md#multus-cni

<!-- Badges -->

[Apache 2.0]: https://opensource.org/licenses/Apache-2.0
[Apache 2.0 Badge]: https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg?style=flat-square
[GitHub Releases]: https://github.com/openvnf/cni-node/releases
[GitHub Release Badge]: https://img.shields.io/github/release/openvnf/cni-node/all.svg?style=flat-square
[Multus Badge]: https://img.shields.io/badge/Multus%20CNI-v3.1-green.svg?style=flat-square
[Multus Release]: https://github.com/intel/multus-cni/releases/tag/v3.1
[CNI Plugins Badge]: https://img.shields.io/badge/CNI%20Plugins-v0.7.5-green.svg?style=flat-square
[CNI Plugins Release]: https://github.com/containernetworking/plugins/releases/tag/v0.7.5
