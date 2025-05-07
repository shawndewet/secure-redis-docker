# Redis Secure Docker Setup

This project sets up Redis securely inside Docker with TLS certificates issued by Let's Encrypt.
Nginx acts as a reverse proxy for the Let's Encrypt process.
It also configures RedisInsight for access via SSH tunnel.

## Prerequisites:
### The following prerequisites need to be installed onto your Linux Server.
- make
- docker

### The DNS for your-real-domain.com needs to have an A record pointed at the public IP Address of your Linux Server
---

## 1. Clone Project
- Clone the repo to your Linux VM.
  ```bash
  git clone [repo url]
  cd [folder created by clone process]
  ```

## 2. Change vm.overcommit_memory setting for Redis optimal performance
```bash
make fix-memory
```

## 3. Create Docker Volumes
```bash
make volumes
```
This creates docker volumes to be used by the containers.

## 4. Create `.env` file
Edit `.env`:
```bash
cp .env.example .env && nano .env
```
Set your real values:
```bash
DOMAIN=your-real-domain.com
EMAIL=your-email@example.com
REDIS_PASSWORD=VeryStrongRandomPassword
```

## 5. Prepare Configuration Files
```bash
make init
```
This substitutes your domain and password from .env into nginx and redis configs.

## 6. Certify your SSL
```bash
make certify
```
This configures nginx for the certify step, and spins up the nginx and certbot containers,
and executes the SSL certification process.

## 7. Restart
```bash
make restart
```
This restarts all the containers in the docker-compose.yml file

## 8. Verify Certificates (optional self-satisfaction check) 
Check certs inside nginx container:
```bash
docker exec -it nginx ls /etc/letsencrypt/live/
```

## 9. Test Redis Secure Connection (optional self-satisfaction check) 
Inside Docker:
```bash
docker run -it --rm redis:7-alpine redis-cli --tls -h redis -p 6379 -a YourStrongRandomPassword
```

Outside Docker:
```bash
redis-cli -h yourdomain.com -p 6379 --tls --cacert /path/to/fullchain.pem -a YourStrongRandomPassword
```

Should respond:
```bash
127.0.0.1:6379> ping
PONG
```

## 10. Watch Logs (Optional)
```bash
make logs
```

## Connect to RedisInsight
From your workstation, establish an SSH tunnel for port 5540:
```bash
ssh -L 5540:localhost:5540 username@linuxvmip
```
Then browse to http://localhost:5540

Create a redis server connection using the your-real-domain.com as the hostname (and remember to indicate Use TLS on the Security tab)

---

# 🧹 Useful Commands

| Command | Purpose |
|:---|:---|
| `make init` | Prepare nginx and redis configs from `.env` |
| `make certify` | Deploy nginx for certification, request cert, reconfigure nginx for prod (follow this with `make restart`) |
| `make logs` | View logs from all containers |
| `make restart` | Restart all services |
| `make renew` | Force certificate renewal |
| `make clean` | Tear down all containers and volumes |

---

# 📈 Notes

- certbot auto-renews every 6 hours
- Docker containers auto-restart on VM reboot
- Redis is secured behind SSL and AUTH

---
