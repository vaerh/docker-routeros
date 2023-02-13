Docker container to run Mikrotik RouterOS

### Usage

```
docker run -d --rm \
  --cap-add=NET_ADMIN \
  -v /dev/net/tun:/dev/net/tun \
  -p 2222:22   \
  -p 8728:8728 \
  -p 8729:8729 \
  -p 5900:5900 \
  --name routeros-$(head -c 4 /dev/urandom | xxd -p)-$(date +'%Y%m%d-%H%M%S') \
vaerhme/routeros:latest
```

Docker Hub Page: https://hub.docker.com/r/vaerhme/routeros

### Notes
Now you can connect to your RouterOS container via VNC protocol
(on localhost 5900 port) and via SSH (on localhost 2222 port).

## List of exposed ports

| Description | Ports |
|-------------|-------|
| Defaults    | 21, 22, 23, 80, 443, 8291, 8728, 8729 |
| IPSec       | 50, 51, 500/udp, 4500/udp |
| OpenVPN     | 1194/tcp, 1194/udp |
| L2TP        | 1701 |
| PPTP        | 1723 |

## Links
* https://github.com/EvilFreelancer/docker-routeros
* https://github.com/joshkunz/qemu-docker
* https://github.com/ennweb/docker-kvm
