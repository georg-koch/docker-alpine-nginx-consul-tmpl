FROM codizz/nginx
MAINTAINER Georg Koch <dev@codizz.de>

COPY consul-template-v0.12.0  /usr/local/bin/consul-template

COPY consul-template.conf     /usr/local/consul-template/consul-template.conf
COPY nginx-server.ctmpl       /usr/local/consul-template/nginx-server.ctmpl
COPY entrypoint.sh            /usr/local/consul-template/entrypoint.sh

COPY nginx.conf               /etc/nginx/nginx.conf
COPY nginx-server.conf        /etc/nginx/conf.d/nginx-server.conf

RUN chmod +x /usr/local/bin/consul-template
RUN chmod +x /usr/local/consul-template/entrypoint.sh

CMD /usr/local/consul-template/entrypoint.sh
