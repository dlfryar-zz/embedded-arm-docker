# Docker Open Embedded TS-7600 Embedded Arm

An [Open Embedded](https://www.openembedded.org/wiki/Getting_started) build enviroment for [TS-7600](https://www.embeddedarm.com/products/TS-7600)

## Starting up a container with Docker Compose
docker-compose -f resources/ts7600_dev.yml -f ts7600/compose.yml up -d

## Tearing down the container with Docker Compose
docker-compose -f resources/ts7600_dev.yml -f ts7600/compose.yml down

## Watching the container logs while it's building/running
docker logs -f ts7600_dev

## Remove the container image once the container is torn down
docker rmi ts7600_dev

