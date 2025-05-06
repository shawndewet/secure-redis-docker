include .env

.PHONY: init deploy renew clean logs restart

init:
	@echo "🔧 Initializing Nginx and Redis configs with domain: $(DOMAIN)"
	@export DOMAIN=$(DOMAIN) && envsubst '$$DOMAIN' < nginx/nginx.conf > nginx/nginx.conf.generated
	@mv nginx/nginx.conf.generated nginx/nginx.conf
	@export REDIS_PASSWORD=$(REDIS_PASSWORD) && envsubst '$$REDIS_PASSWORD' < redis/redis.conf > redis/redis.conf.generated
	@mv redis/redis.conf.generated redis/redis.conf

deploy:
	@echo "🚀 Starting nginx and certbot containers..."
	docker compose -f docker-compose.prod.yml up -d nginx certbot
	@echo "🔒 Requesting Let's Encrypt certificate for $(DOMAIN)..."
	docker run --rm -v redis-secure-docker_certs:/etc/letsencrypt certbot/certbot certonly \
		--webroot --webroot-path=/var/www/certbot \
		-d $(DOMAIN) --email $(EMAIL) --agree-tos --no-eff-email
	@echo "🧠 Starting Redis container..."
	docker compose -f docker-compose.prod.yml up -d redis
	@echo "✅ Deployment completed!"

renew:
	@echo "🔄 Forcing certificate renewal..."
	docker run --rm -v redis-secure-docker_certs:/etc/letsencrypt certbot/certbot renew --force-renewal --webroot --webroot-path=/var/www/certbot
	@echo "✅ Certificates renewed."

clean:
	@echo "🧹 Stopping and cleaning up containers and volumes..."
	docker compose -f docker-compose.prod.yml down
	docker volume rm redis-secure-docker_certs
	@echo "✅ Cleaned up."

logs:
	@echo "📜 Showing logs..."
	docker compose -f docker-compose.prod.yml logs -f

restart:
	@echo "♻️ Restarting all services..."
	docker compose -f docker-compose.prod.yml down
	docker compose -f docker-compose.prod.yml up -d
