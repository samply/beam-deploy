# Beam Dev Deployment Package

## Martin's Quickstart

1. Checkout this repo, e.g. to `/srv/docker/beam-broker`
2. Copy `.env.template` to `.env`, adapt to your needs
3. Run `./pki-scripts/initial_vault_setup.sh` to setup your initial vault. Note down the unseal key.
4. Run `./pki-scripts/create_privkey_and_cert.sh dummy` to create a dummy certificate for the Broker.
5. Start manually using `docker-compose up` or use supplied systemd unit to restart upon boot.
6. If Beam keeps outputting messages like "Vault is not yet unsealed" (likely on each restart), run `VAULT_ADDR=http://localhost:8200 vault operator unseal` and enter the unseal key you got in step 3.

## Old text (to be merged / overhauled)

This package should enable developers to easily deploy Beam in multiple
scenarios:

1) Start the central components
2) Start the local components
3) Start a dev-setup consisting of the central components and to local
   components on the same machin

## Usage
The starting and initialization of all components is performed via `beamdev`.
Depending on the scenario, different environment variables must be set. All
scenarios are detailed below.

### Central Components
#### Run the Central components
To initialize and start the central components the environment
variable `BROKER_ID` must be set. To start the components use, e.g.,
```
BROKER_ID=broker.example.de ./beamdev start_central
```

#### Stop the Central Components

```
BROKER_ID=broker.example.de ./beamdev stop central
```

#### Generate Proxy Certificates

```
BROKER_ID=broker.example.de pki/pki.sh request_proxy <proxy_short_id>
```
Creates an archive with `pki.secret` and `<proxy_short_id>/priv.pem`.

### Local Proxy
#### Run the Local Proxy
To initialize and start the central components the environment
variables `BROKER_ID` and the `PROXY_ID` must be set. Additionally, one or more apps can be registered via the environment variables `APP_0_ID` and `APP_0_KEY` with incrementing numbers.
The default values are `APP_0_ID=app1` and `APP_0_KEY=App1Secret`.
To start the components use, e.g.,
DOes not clean, expects certs in pki/
```
APP_0_ID=app APP_0_KEY=AppKey PROXY_ID=p1.broker.example.de BROKER_ID=broker.example.de ./beamdev start_local
```

#### Stop the Central Components

```
BROKER_ID=broker.example.de ./beamdev stop local
```

### Dev-Setup
#### Run the all components
To initialize and start the full dev-setup the environment
variables `BROKER_ID`, `PROXY1_ID`, and `PROXY2_ID` must be set. Additionally, one or more apps can be registered via the environment variables `APP_0_ID` and `APP_0_KEY` with incrementing numbers. This information is used to register apps on both proxies.
The default values are `APP_0_ID=app1` and `APP_0_KEY=App1Secret`.
To start the components use, e.g.,
```
APP_0_ID=app APP_0_KEY=AppKey PROXY1_ID=p1.broker.example.de PROXY2_ID=p1.broker.example.de BROKER_ID=broker.example.de ./beamdev start_dev
```

#### Stop the Central Components

```
BROKER_ID=broker.example.de ./beamdev stop dev
```
