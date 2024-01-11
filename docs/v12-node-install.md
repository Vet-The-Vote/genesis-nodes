# V12 Node Installation


## Building the V12 Node

To build the V12 node execute:

```shell script
export VERSION_NUMBER=0.9.1.beta
VERSION_NUMBER=0.9.1.beta docker-compose build
docker push registry.cybertron.ninja/v12node:${VERSION_NUMBER}
```

## Running the V12 Node on localhost

To run the V12 node on your local workstation execute the following:

```shell script
echo "V12_private_key_1" | docker secret create V12_LOCALHOST_BIOS_PRIVATE_KEY -
echo "V12_private_key_2" | docker secret create V12_LOCALHOST_VALIDATOR1_PRIVATE_KEY -
echo "V12_private_key_3" | docker secret create V12_LOCALHOST_VALIDATOR2_PRIVATE_KEY - 
echo "V12_private_key_4" | docker secret create V12_LOCALHOST_VALIDATOR3_PRIVATE_KEY - 
VERSION_NUMBER=0.9.1.beta docker stack deploy -c stack.localhost.yaml v12
```

## Build the V12 Node for JONIN

```shell script
#VERSION_NUMBER=jonin docker-compose build
docker image tag registry.cybertron.ninja/v12node:${VERSION_NUMBER} registry.cybertron.ninja/v12node:jonin
docker push registry.cybertron.ninja/v12node:jonin
```

## Running the V12 Node on jonin

To run the V12 nodes on `jonin` execute the following:

```shell script
docker stack deploy -c stack.jonin.yaml --with-registry-auth v12
```





