# Beam Dev Deployment Package

This package should enable developers to easily deploy Beam in multiple scenarios:

1) Start the central components
2) Start the local components
3) Start a dev-setup consisting of the central components and to local components on the same machin

## Usage
The starting and initialization of all components is performed via `beamdev`. Depending on the scenario, different environment variables must be set. All scenarios are detailed below.

### Central Components

#### Run the Central components
To initialize and start the central components the environment variable `BROKER_ID` must be set. Starting the components triggers a clean, i.e., all previously generated certificates are cleaned up.
To start the components use, e.g.,
```
BROKER_ID=broker.example.de ./beamdev start_central
```

#### Stop the Central Components

```
./beamdev stop central
```

#### Generate Proxy Certificates

```
BROKER_ID=broker.example.de pki/pki.sh request_proxy <proxy_short_id>
```
Creates an archive including `pki.secret` and `<proxy_short_id>/priv.pem`.

-----

### Local Proxy
#### Run the Local Proxy
To initialize and start the central components the environment variables `BROKER_ID`, `PROXY_ID`, and `VAULT` must be set. Additionally, one or more apps can be registered via the environment variables `APP_0_ID` and `APP_0_KEY` with incrementing numbers.
The default values are `APP_0_ID=connect` and `APP_0_KEY=ConnectSecret`.
Starting the local components does not perform a directory clean, as `pki.secret` and `<proxy_short_id>.priv.pem` are expected in the `pki/` directory.
To start the components use, e.g.,
```
VAULT=https://ca.example.de PROXY_ID=p1.broker.example.de BROKER_ID=broker.example.de DISCOVERY_URL=https://locationservice.example.de ./beamdev start_local
```

#### Stop the local proxy

```
./beamdev stop local
```

-----

### Dev-Setup
#### Run the all components
To initialize and start the full dev-setup the environment variables `BROKER_ID`, `PROXY1_ID`, and `PROXY2_ID` must be set. Additionally, one or more apps can be registered via the environment variables `APP_0_ID` and `APP_0_KEY` with incrementing numbers. This information is used to register apps on both proxies. The default values are `APP_0_ID=connect` and `APP_0_KEY=ConnectSecret`.
To start the components use, e.g.,
```
PROXY1_ID=p1.broker.example.de PROXY2_ID=p1.broker.example.de BROKER_ID=broker.example.de DISCOVERY_URL=https://locationservice.example.de ./beamdev start_dev
```

#### Stop all components

```
./beamdev stop dev
```
