# V12 Node Installation

To build the V12 node execute:

```shell script
VERSION_NUMBER=0.9.beta docker-compose build
```

To run the V12 node execute:

```shell script
export EOS_PUB_KEY=EOS7XHH6htVrHa9uQSNdhj1JbJ5RzURACEMXdxmV2Cbk4E8NGhWQ7
export EOS_PRIV_KEY=# TODO: add private key using Docker secrets
VERSION_NUMBER=0.9.beta docker-compose up
```




