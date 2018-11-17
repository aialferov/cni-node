# CNI Node

[![License: Apache-2.0][Apache 2.0 Badge]][Apache 2.0]
[![GitHub Release Badge]][GitHub Releases]
![Multus Badge]
![CNI Plugins Badge]

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

Install plugins:

```
$ docker run --rm \
    -v <Dest Dir>:/host/opt/cni/bin \
    openvnf/cni-node install --plugins=<Plugins> # comma separated
```

Install CNI configuration from a template:

```
$ docker run --rm \
    -v <Dest Dir>:/host/etc/cni/net.d \
    -v <Template Path>:/etc/cni/net.d/<Template File> \
    openvnf/cni-node install --config=<Template File>
```

"Template File" might contain special pointers named after existing in the
"Dest Dir" CNI configuration files. Each pointer will be replaced by the
corresponding file content in a final configuration file.

For example, if a template contains the following line:

```
__10-calico.conflist__
```

and file with the name "10-calico.conflist" exists in the "Dest Dir", then
content of this file will be inserted instead of the pointer.

To install plugins and configuration in one run specify "--plugins" and
"--config" options simultaneously.

### Uninstall CNI

To uninstall plugins and configuration replace "install" with "uninstall" in
the instructions above.

### Wait

To wait for SIGING or SIGTERM signal after install or uninstall action add
"--wait" option.

## Docker Example

Consider installing Ipvlan CNI plugin and its configuration on a node.

Provided an Ipvlan configuration template:

```
$ cat ipvlan.tmpl
{
    "name": "mynet",
    "type": "ipvlan",
    "master": "eth2",
    "ipam": {
        "type": "host-local",
        "subnet": "172.19.2.0/24"
    }
}
```

Install CNI plugin and its configuration:

```
$ docker run --rm \
    -v /opt/cni/bin:/host/opt/cni/bin \
    -v /etc/cni/net.d:/host/etc/cni/net.d \
    -v $PWD/ipvlan.tmpl:/etc/cni/net.d/05-ipvlan.conf \
    openvnf/cni-node install --plugins=ipvlan --config=05-ipvlan.conf

Installing CNI plugin ipvlan...
Done.
Installing CNI configuration from 05-ipvlan.conf...
### /etc/cni/net.d/05-ipvlan.conf ###
{
    "name": "mynet",
    "type": "ipvlan",
    "master": "eth2",
    "ipam": {
        "type": "host-local",
        "subnet": "172.19.2.0/24"
    }
}
###
```

## Kubernetes Example

The example uses [DaemonSet] to install Multus and Macvlan CNI plugins on each
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

<!-- Badges -->

[Apache 2.0]: https://opensource.org/licenses/Apache-2.0
[Apache 2.0 Badge]: https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg?style=flat-square
[GitHub Releases]: https://github.com/travelping/cennsonic/releases
[GitHub Release Badge]: https://img.shields.io/github/release/openvnf/cni-node/all.svg?style=flat-square
[Multus Badge]: https://img.shields.io/badge/Multus%20CNI-v3.1-green.svg?style=flat-square
[CNI Plugins Badge]: https://img.shields.io/badge/CNI%20Plugins-v0.7.4-green.svg?style=flat-square
