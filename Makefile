.PHONY: build up down logs test clean

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

test:
	"C:\Program Files\Git\bin\bash.exe" ./scripts/healthcheck.sh http://localhost:5000

clean:
	docker compose down -v