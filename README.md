## license_auto
Backend tasks for OpenSource License recognizing

## Requirements
* RabitMQ
* Ruby 2.2.x

# Usage
``` bash
# startup Erlang node
service rabbitmq-server start 
# stop Erlang node
rabbitmqctl stop
# You MUST work in this dir
cd license_auto
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



