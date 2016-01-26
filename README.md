![Circle CI](https://img.shields.io/circleci/project/codizz/docker-alpine-nginx-consul-tmpl.svg)
![Docker Stars](https://img.shields.io/docker/stars/codizz/nginx-consul-tmpl.svg)
![Docker Pulls](https://img.shields.io/docker/pulls/codizz/nginx-consul-tmpl.svg)
[![Image Size](https://img.shields.io/imagelayers/image-size/codizz/nginx-consul-tmpl/latest.svg)](https://imagelayers.io/?images=codizz/nginx-consul-tmpl:latest)
[![Image Layers](https://img.shields.io/imagelayers/layers/codizz/nginx-consul-tmpl/latest.svg)](https://imagelayers.io/?images=codizz/nginx-consul-tmpl:latest)

### Supported tags

* [`latest`](https://github.com/codizz/docker-alpine-nginx-consul-tmpl/tree/master)([latest/Dockerfile](https://github.com/codizz/docker-alpine-nginx-consul-tmpl/tree/master/Dockerfile))
* 
### Project

The Docker image is based on [docker-alpine](https://github.com/gliderlabs/docker-alpine) v3.3 with installed `nginx` v1.8.0-r3 and `consul template` v0.12.

### Usage

First clone this repository and switch into.

In this test set-up I use:

  * [consul-server](https://github.com/gliderlabs/docker-consul) version 0.6
  * [registrator](https://github.com/gliderlabs/registrator) v6 

#### Run consul/registrator/nginx stack

Export the environments variables:

 * `export BRIDGE_IP=172.17.0.1`   - Docker deamon bridge address (docker0) 
 * `export PRIVATE_IP=10.0.2.15`   - Private host IP address 
 * `export HOST_NAME=my-host-name` - Hostname for consul docker container

Run the stack. The command `envsubst` replaces all placeholders in `run.yml.tmpl` with values of environments variables and creates `run.yml` file. 

    envsubst < "run.yml.tmpl" > "run.yml" | docker-compose -f run.yml -p server up -d

If `envsubst` not installed, you can use `sed` for replacing environment variables in the `run.yml.tmpl` file with the their values or do it manually.

Look into the log output from your running stack.

    docker-compose -f run.yml -p server logs

Now open the browser and navigate to http://localhost:8500. You will see Consul UI with the initial registered services.

![Consul-UI](https://raw.githubusercontent.com/codizz/docker-alpine-nginx-consul-tmpl/master/images/consul-1-initial.png)

Actually we don't registered own dockerized application. So if you try to access http://localhost, you will get `502 Bad Gateway` from nginx server.

Look into the generated `nginx-server.conf` file

    docker exec -t server_nginx_1 cat /etc/nginx/conf.d/nginx-server.conf
    
You will see the following content:

```
upstream foo {
  least_conn;
  server 127.0.0.1:65535; # return 502

}

server {
        listen 80;
        server_name _;

        location / {
                proxy_pass http://foo;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
        }
}
```

It means, the services *service-foo* is not registered (look into `nginx-server.ctmpl`), so the *upstream* refer to *502*.

#### Register own dockerized application

Run dockerized service *foo*

    docker-compose -f ./dockerized-app/run.yml up -d
    
This will build the Docker image for the service *foo* and start this. The service name *service-foo* is described in the Dockerfile (*./dockerized-app/Dockerfile*) by setting environment variable.

Refresh your browser http://localhost:8500. You see *service-foo* is now registered in the consul service discovery:

![Consul-UI](https://raw.githubusercontent.com/codizz/docker-alpine-nginx-consul-tmpl/master/images/consul-2-registered.png)

Access the service with http://localhost. You see the *service-foo* ui.

In the generated `nginx-server.conf` file you see the upstream configuration now

    docker exec -t server_nginx_1 cat /etc/nginx/conf.d/nginx-server.conf

with the Content:

```
upstream foo {
  least_conn;
  server 127.0.1.1:32768 ;

}

server {
        listen 80;
        server_name _;

        location / {
                proxy_pass http://foo;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
        }
}
```

#### Optimize upstream configuration

As you can see in the *nginx-server.ctmpl*, you can configure upstream.

```
upstream foo {
  least_conn;
  {{range service "service-foo"}}server {{.Address}}:{{.Port}} {{range tree "upstream-config@dc1"}} {{.Key}}={{.Value}} {{end}};
    {{else}}server 127.0.0.1:65535; # return 502
  {{end}}
}

....
```

It means, you can create key/value pairs in the consul key/value-store in the folder *upstream-config*.

So, at first create *upstream-config/* folder. Add a configuration you need, for example *max_conns=5*.

The `nginx-server.conf` file is updated automatically

    docker exec -t server_nginx_1 cat /etc/nginx/conf.d/nginx-server.conf

Find your *max-conns* configuration there:

```
upstream foo {
  least_conn;
  server 127.0.1.1:32768  max_conns=5 ;

}
....
```

**Congratulations!**
**First steps in the direction 'blue/green' deployment are done.**


### License

MIT
