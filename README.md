NATS on Autopilot

This image uses ContainerPilot to register NATS with Consul. As you scale out the number of NATS containers they will be automatically clustered together. Furthermore, a health check is also performed in the container to ensure that each NATS instance is healthy.

## Environment Variables

- _CONSUL_ hostname where consul can be found
- _CONSUL_AGENT_ determines if the consul agent is executed in the container
- _LOG_LEVEL_ ContainerPilot specific log level to use, defaults to INFO
- _NATS_USER_ username to use for cluster authorization, defaults to ruser
- _NATS_PASSWORD_ password to user for cluster authorization, defaults to T0pS3cr3t

## Prerequisites

Please either run `setup.sh` to create a `_env` file or create one manually. The `setup.sh` script expects that the [triton-cli](https://www.npmjs.com/package/triton) is installed and a profile is setup for docker to connect to a Triton datacenter.

## Example Usage

```
docker-compose -f local-compose.yml up -d
docker-compose -f local-compose.yml scale nats=3
```

Look at the monitoring page for routez for one of the NATS servers and observe that they are clustered.
