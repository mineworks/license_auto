#!/usr/bin/env bash

cat /root/.bash_profile
export license_auto_rabbit_mq="amqp://guest:guest@localhost:5672"
export github_username=Your Github Username
# https://help.github.com/articles/creating-an-access-token-for-command-line-use/
export github_password=Your Github Personal access tokens
export license_auto_proxy='proxy.foo.com:8080'

apt-get install -y rabbitmq-server \
    libpq-dev build-essential \
    libxml2 \
    libxslt bzip2 cmake

# If mac osx
# brew install icu4c

rabbitmq-plugins enable rabbitmq_management
rabbitmqctl stop # 停止Erlang节点
service rabbitmq-server start # 启动Erlang节点

bundle install

pip install -r ../requirements.txt
cp conf/supervisord.conf /etc/supervisord.conf
supervisord

cp conf/.git-credentials ~/.git-credentials
git config --global credential.helper 'store --file ~/.git-credentials'
git config --global http.proxy http://proxy.mycompany:80




