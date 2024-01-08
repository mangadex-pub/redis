# Redis

This is a downstream image of [Bitnami's Redis image](https://github.com/bitnami/containers/tree/main/bitnami/redis), with the following additional modules:
- [RedisJSON](https://github.com/RedisJSON/RedisJSON)
- [RediSearch](https://github.com/RediSearch/RediSearch)

The modules are installed in `/opt/mangadex/redis-modules`, you can `loadmodule /path/to/module/file.so`.

We haven't yet tested it well-enough on our end to be able to recommend it. So you shouldn't even think of using it for anything serious.
