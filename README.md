# license_auto
Backend tasks for OpenSource License recognizing

# Usage
``` bash
cd license_auto  # Required
service rabbitmq-server start # startup Erlang node
rabbitmqctl stop # stop Erlang node
./script/apt-get.deps.sh
./bin/mq_pack.rb
./bin/mq_repo.rb
```

# Test
``` bash
$ rake test
```

# TODO
* speed up License name recognizing.



