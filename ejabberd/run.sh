#!/bin/sh

if [ "$TYPE" = "ecs" ]; then
    export HOST_ADDRESS=$(echo $HOSTNAME | grep -o '[0-9]\{1,3\}\-[0-9]\{1,3\}\-[0-9]\{1,3\}\-[0-9]\{1,3\}' | sed 's/-/\./g')
else
    export HOST_ADDRESS=$HOSTNAME
fi

if [ ! -d "eja" ]; then
    mkdir ./eja
    ./eja.run --prefix $EJABBERD_HOME/eja --mode unattended \
        --adminpw $EJABBERD_ADMIN_PASSWORD --hostname $HOST_ADDRESS --cluster 1 \
        --ejabberddomain $EJABBERD_DOMAIN --debuglevel 4 --debugtrace /tmp/ejabberd.log

    chmod +x -R $EJABBERD_HOME
    touch .erlang.cookie
    chmod 600 .erlang.cookie
    echo $EJABBERD_COOKIE_SECRET > .erlang.cookie

    cp $EJABBERD_HOME/ejabberdctl.cfg $EJABBERD_HOME/eja/conf/ejabberdctl.cfg && $EJABBERD_HOME/ejabberdctl.cfg
    sed -i 's/##ERLANG_NODE##/ejabberd@'$HOST_ADDRESS'/' $EJABBERD_HOME/eja/conf/ejabberdctl.cfg

    #Enable Permissions in Ejabberd
    sed -i -r 's#- ip: "127.0.0.1/8"#- all#g' $EJABBERD_HOME/eja/conf/ejabberd.yml
    sed -i 's/- "connected_users_number"//' $EJABBERD_HOME/eja/conf/ejabberd.yml
    sed -i 's/- "status"/- "*"/' $EJABBERD_HOME/eja/conf/ejabberd.yml
    sed -i 's/## auth_password_format: plain/auth_password_format: plain/' $EJABBERD_HOME/eja/conf/ejabberd.yml
fi

$EJABBERD_HOME/eja/bin/ejabberdctl start

#Cluster
if [ "$TYPE" = "ecs" ] && [ "$ECS_DNS_REGISTRY" != "" ]; then
    sleep 5
    ip=$(dig +short $ECS_DNS_REGISTRY | grep -v $HOST_ADDRESS | shuf -n 1)

    if [ "$ip" != "" ]; then
        echo "Try cluster node $HOST_ADDRESS to $ip"
        $EJABBERD_HOME/eja/bin/ejabberdctl join_cluster "ejabberd@$ip"
    fi
fi

tail -f $EJABBERD_HOME/eja/logs/install.log \
    $EJABBERD_HOME/eja/logs/error.log \
    $EJABBERD_HOME/eja/logs/crash.log \
    $EJABBERD_HOME/eja/logs/ejabberd.log