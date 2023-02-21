# Beam Dev Deployment Package

## Martin's Quickstart

1. Checkout this repo, e.g. to `/srv/docker/beam-broker`
2. Copy `.env.template` to `.env`, adapt to your needs
3. Run `./pki-scripts/initial_vault_setup.sh` to setup your initial vault. Note down the unseal key.
4. Run `./pki-scripts/create_privkey_and_cert.sh broker` to create a dummy certificate for the Broker.
5. Start manually using `docker-compose up` or use supplied systemd unit to restart upon boot.
6. If Beam keeps outputting messages like "Vault is not yet unsealed" (likely on each restart), run `VAULT_ADDR=http://localhost:8200 vault operator unseal` and enter the unseal key you got in step 3.
