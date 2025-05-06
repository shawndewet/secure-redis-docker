# Redis Secure Docker Setup

This project runs Redis securely inside Docker with TLS certificates issued by Let's Encrypt.
Nginx acts as a reverse proxy, and all certificates are managed inside Docker containers.

---

# 🏁 First Run Checklist

## 1. Upload / Extract Project
- Clone the repo to your Linux VM.
- Extract:
  ```bash
  git clone [repo url]
  ```

## 2. Edit `.env` file
Edit `.env`:
```bash
nano .env
```
Set your real values:
```bash
DOMAIN=your-real-domain.com
EMAIL=your-email@example.com
REDIS_PASSWORD=VeryStrongRandomPassword
```

## 3. Open Ports
Ensure ports 80 and 443 are allowed in the firewall.

Example (UFW):
```bash
sudo ufw allow 80
sudo ufw allow 443
```

## 4. Prepare Configuration Files
```bash
make init
```
This substitutes your domain and password into nginx and redis configs.

## 5. Deploy Nginx and Certbot
```bash
make deploy
```

## 6. Verify Certificates
Check certs inside nginx container:
```bash
docker exec -it nginx ls /etc/letsencrypt/live/
```

## 7. Test Redis Secure Connection
Inside Docker:
```bash
docker run -it --rm --network redis-secure-docker_default redis:7-alpine redis-cli --tls --cacert /certs/live/yourdomain.com/fullchain.pem -h redis -p 6379 -a YourStrongRandomPassword
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

## 8. Watch Logs (Optional)
```bash
make logs
```

---

# 🧹 Useful Commands

| Command | Purpose |
|:---|:---|
| `make init` | Prepare nginx and redis configs from `.env` |
| `make deploy` | Deploy nginx, request cert, then start redis |
| `make logs` | View logs from all containers |
| `make restart` | Restart all services |
| `make renew` | Force certificate renewal |
| `make clean` | Tear down all containers and volumes |

---

# ✅ First Run Success Criteria

- [ ] HTTPS access gives 502 Bad Gateway (expected initially)
- [ ] Nginx, Redis, Certbot are healthy (`make logs`)
- [ ] Secure `redis-cli` connection via TLS and password
- [ ] No unencrypted ports exposed

---

# 📈 Notes

- certbot auto-renews every 6 hours
- Docker containers auto-restart on VM reboot
- Redis is secured behind SSL and AUTH

---
