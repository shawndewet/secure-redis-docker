include .env

.PHONY: init deploy renew clean logs restart

init:
	@echo "🔧 Initializing Nginx and Redis configs with domain: $(DOMAIN)"
	@DOMAIN=$(DOMAIN) && envsubst '$$DOMAIN' < nginx/nginx.certonly.conf > nginx/nginx.certonly.conf.generated
	@mv nginx/nginx.certonly.conf.generated nginx/nginx.certonly.conf
	@DOMAIN=$(DOMAIN) && envsubst '$$DOMAIN' < nginx/nginx.full.conf > nginx/nginx.full.conf.generated
	@mv nginx/nginx.full.conf.generated nginx/nginx.full.conf
	@DOMAIN="$(DOMAIN)" REDIS_PASSWORD="$(REDIS_PASSWORD)" envsubst '$$DOMAIN $$REDIS_PASSWORD' < redis/redis.conf > redis/redis.conf.generated
	@mv redis/redis.conf.generated redis/redis.conf

create-volumes:
	@echo "🛠 Creating global Docker volumes 'certs' and 'certbot-htdocs' if missing..."
	@if ! sudo docker volume inspect certs >/dev/null 2>&1; then sudo docker volume create certs; else echo "✅ Volume 'certs' already exists."; fi
	@if ! sudo docker volume inspect certbot-htdocs >/dev/null 2>&1; then sudo docker volume create certbot-htdocs; else echo "✅ Volume 'certbot-htdocs' already exists."; fi
	@echo "✅ Volume creation completed."

certify:
	@echo "🚀 Copying certonly nginx config..."
	cp nginx/nginx.certonly.conf nginx/nginx.conf
	@echo "🚀 Starting nginx and certbot containers..."
	sudo docker compose -f docker-compose.yml up -d nginx certbot
	@echo "🔒 Requesting Let's Encrypt certificate for $(DOMAIN)..."
	sudo docker run --rm \
		-v certs:/etc/letsencrypt \
		-v certbot-htdocs:/var/www/certbot \
		certbot/certbot certonly \
		--webroot --webroot-path=/var/www/certbot \
		-d $(DOMAIN) --email $(EMAIL) --agree-tos --no-eff-email
	cp nginx/nginx.full.conf nginx/nginx.conf
	@echo "✅ Certified.  Now run make restart."

renew:
	@echo "🔄 Forcing certificate renewal..."
	sudo docker run --rm \
		-v certs:/etc/letsencrypt \
		-v certbot-htdocs:/var/www/certbot \
		certbot/certbot renew --force-renewal --webroot --webroot-path=/var/www/certbot
	@echo "✅ Certificates renewed."

clean:
	@echo "🧹 Stopping and cleaning up containers and volumes..."
	sudo docker compose -f docker-compose.yml down
	sudo docker volume rm certs
	sudo docker volume rm certbot-htdocs
	@echo "✅ Cleaned up."

logs:
	@echo "📜 Showing logs..."
	sudo docker compose -f docker-compose.yml logs -f

restart:
	@echo "♻️ Restarting all services..."
	sudo docker compose -f docker-compose.yml down
	sudo docker compose -f docker-compose.yml up -d

health:
	@echo "🔎 Checking Docker container statuses..."
	sudo docker ps --filter "name=nginx" --filter "name=redis" --filter "name=certbot"

	@echo "🔎 Checking if certificates exist..."
	sudo docker exec nginx ls /etc/letsencrypt/live/$(DOMAIN) || (echo "❌ Certificates not found!" && exit 1)

	@echo "🔎 Checking if Redis is reachable over TLS..."
	sudo docker run --rm --network redis-secure-docker_default redis:7-alpine redis-cli --tls --cacert /certs/live/$(DOMAIN)/fullchain.pem -h redis -p 6379 -a $(REDIS_PASSWORD) ping || (echo "❌ Redis PING failed!" && exit 1)

	@echo "✅ All health checks passed!"

