# Beam Deployment Package
This repository will help you set up your own beam broker instance.

## Requirements
Before starting with the installation, ensure you have the following software installed:
- [docker](https://www.docker.com/)
- As our script currently requires the command `docker-compose` you need to add the script `/bin/docker-compose` to your server with following content `docker compose "$@"`.
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
