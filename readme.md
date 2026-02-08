# HomeLab Kubernetes Cluster

With this repository, a homelab kubernetes cluster running on TalosOS is deployed, alongside a FluxCD installation. With the included kubernetes configuration, `MetalLB`, `Traefik`, `Longhorn`, `Headlamp` are deployed. 

## Prerequisits

A local working installation of the follwoing utilities is required.

- [OpenTofu](https://opentofu.org/docs/intro/install/)
- [talosctl](https://docs.siderolabs.com/talos/v1.12/getting-started/talosctl)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/docs/intro/install/)
- [Flux](https://fluxcd.io/flux/installation/)
- **gnupg, sops** for in-repository encryption. `brew install gnupg sops`

## Getting started

The setup can be divided into multiple parts, only the first one being absolutely required. 

1. Setup VM infrastructure: a kubernetes cluster running on talos will be started, with FluxCD installed as well as the basic infrastructure defined in the `flux` folder.
2. Instantiate apps: once ready, FluxCD can be used to deploy additional apps from another repository or folder. 
3. Apply backups (for disaster recovery)

### Infrastructure

The entire infrastructure is hosted on a proxmox cluster. Everything is set up in `tofu/main.tf`. Access to proxmox is configured in the `tofu/creds` folder, which must contain the following files.

- `api_token_id.txt`
- `api_token_secret.txt`
- `api_url.txt`

Next, create a copy of all `*.example.tfvars` files, and populate them with appropriate values. The GitHub Token requires the following permissions to the repository with the code to deploy by flux. 

- Metadata: Read-only
- Administration: Read and write
- Contents: Read and write

```shell
cd tofu
tofu init
tofu refresh # update local configuration with what is deployed
tofu plan
tofu deploy
```

Once up and running, use the following commands to retrieve configurations.

```shell
tofu output kubeconfig 
tofu output talos_configuration
tofu output client_configuration
```

More commands can be found in the [OpenTofu documentation](https://opentofu.org/docs/cli/commands/).

### Accessing Headlamp

Once ready, headlamp is accessible using a token generated with the following command.

```shell
kubectl create token headlamp -n headlamp
```


## Maintenance

### Updating/adding secrets

Secrets are encrypted in-repository using sops and a gpg key. As long as you have the key, the following command can be used to encrypt secrets inline. 

```shell
sops -e -i infrastructure/traefik/traefik.yaml
```

### Updating talos

As there is no possibility yet to update a talos cluster through terraform without taring everything down and up again, for now it is recommendet to use the `talosctl upgrade command`, and sending it to one node after the other.

```shell
$ talosctl upgrade --nodes 10.20.30.40 \
  --image ghcr.io/siderolabs/installer:v1.12.2
```


# todo


- figure out how fluxcd sees all deployments as a single thing, and not just "infrastructure" and add an order in teployment
- metrics-server
- zitadel as a global oicd
  - configure oicd for headlamp
- backup
- update kubeconfig, talosconfig, secrets.yaml