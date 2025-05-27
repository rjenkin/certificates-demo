# Nginx server

The Docker configuration includes an Nginx server initially set up for HTTP connections. Throughout the exercises, we'll generate and install SSL/TLS certificates to enable secure HTTPS communication with this server.

**Start docker:**
```bash
docker-compose up -d
```

**Test docker (HTTP):**

The Nginx server has been configured with two virtual hosts: `server-one` and `server-two`. Since these hostnames aren't in your local DNS or hosts file, you can access them in two ways: either by passing the desired hostname in the HTTP Host header with curl's `-H 'Host: server-name'` option, or by using the `--resolve` flag to map the hostname to the localhost IP address.

```bash
curl http://localhost:10000/

curl -H 'Host: server-one' http://localhost:10000/

curl -H 'Host: server-two' http://localhost:10000/

curl --resolve server-one:10000:127.0.0.1 http://server-one:10000/

curl --resolve server-two:10000:127.0.0.1 http://server-two:10000/
```

