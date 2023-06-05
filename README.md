# Beam Deployment Package
This repository will help you set up your own beam broker instance.

## Requirements
Before starting with the installation, ensure you have the following software installed:
- [docker with docker-compose](https://www.docker.com/)
- [jq](https://stedolan.github.io/jq/)
- [traefik](https://doc.traefik.io/traefik/) reverse proxy with external network `traefik`

## Quickstart
1. Checkout this repo, e.g. to `/srv/docker/beam-broker`
2. Copy `.env.template` to `.env`, adapt to your needs
3. Run `./pki-scripts/initial_vault_setup.sh` to setup your initial vault. **Important:** Note down the unseal key.
4. Run `./pki-scripts/create_privkey_and_cert.sh broker` to create a dummy certificate for the Broker.
5. Start manually using `docker-compose up` or use supplied [systemd unit](./beam-central.service.example) to restart upon boot.

## Maintenance
A collection of common tasks then managing your own broker.
### Unsealing the Vault
If Beam keeps outputting messages like "Vault is not yet unsealed" (likely on each restart), run `docker exec -it -e VAULT_ADDR=http://localhost:8200 beam-broker-vault-1 vault operator unseal` and enter the unseal key you got in step 3 of the Quickstart.

### Signing a CSR
Each site or party that wants to communicate through your beam-broker instance must be verified by you to be accepted by the broker.
For this administration task, we provide a [management tool](https://github.com/samply/managepki), which you can run through the included wrapper script [./pki-scripts/managepki](./pki-scripts/managepki).
You can call the script like this
``` shell
./pki-scripts/managepki sign --csr-file csr/<parties-name>.csr --common-name=<parties-name>.broker.<project-name>.verbis.dkfz.de
```
and follow the instructions as prompted.

### Monitoring Beam Certificate Expiry
To monitor the expiry of all Beam certificates, the [management tool](https://github.com/samply/managepki) implements a warning functionality accessible through the `managepki` wrapper script:
``` shell
./pki-scripts/managepki warn <days until expiry>
```

