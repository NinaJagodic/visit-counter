# visit-counter
                    +---------------------------------------------+
                    |               Docker mreža                  |
                    |                                             |
                    |            +---------+                      |
  Klijent --------> | :5000 ---> |  Nginx  |                      |
  (curl/browser)    |   (->80)   +----+----+                      |
                    |                 |  raspoređuje zahteve      |
                    |         +-------+-------+                   |
                    |         v               v                   |
                    |    +---------+     +---------+              |
                    |    |  web-1  |     |  web-2  |              |
                    |    | (Flask) |     | (Flask) |              |
                    |    +----+----+     +----+----+              |
                    |         |               |                   |
                    |         +-------+-------+                   |
                    |                 v                           |
                    |            +---------+      +----------+    |
                    |            |  Redis  |----->| redis_data|   |
                    |            +---------+      |  (volume) |   |
                    |                             +----------+    |
                    +---------------------------------------------+

# Brojač poseta (visit-counter)

[![CI Pipeline](https://github.com/NinaJagodic/visit-counter/actions/workflows/ci.yml/badge.svg)]
(https://github.com/NinaJagodic/visit-counter/actions/workflows/ci.yml)

Mala Flask aplikacija koja broji posete i čuva brojač u Redis bazi. Spakovana je u Docker, pokreće se preko Docker Compose-a sa Nginx reverse 
proxy-jem i dve instance aplikacije, a CI pipeline (GitHub Actions) radi lint, testove, build, bezbednosno skeniranje i objavljivanje image-a na 
ghcr.io.

## Arhitektura

(ovde nalepi ASCII dijagram odozgo)

## Endpointi

| Endpoint | Ponašanje |
|---|---|
| `GET /` | Poruka i ime hosta (kontejnera) |
| `GET /visits` | Uvećava brojač u Redis-u i vraća vrednost |
| `GET /health` | 200 `{"status":"ok"}` ako je Redis dostupan, inače 503 |

## Preduslovi

- Git
- Docker Desktop (sa Docker Compose)
- (opciono) Python 3.12, za lokalno pokretanje testova i linter-a
- (opciono) `make`, za prečice iz Makefile-a

## Pokretanje

```bash
git clone https://github.com/NinaJagodic/visit-counter.git
cd visit-counter
cp .env.example .env
docker compose up -d --build
```

Provera:

```bash
curl http://localhost:5000/
curl http://localhost:5000/visits
curl http://localhost:5000/health
```

Zaustavljanje: `docker compose down` (podaci u volume-u ostaju). Sa `-v` se briše i brojač.

### Makefile prečice

`make build`, `make up`, `make test`, `make down`, `make logs`, `make clean`

### Healthcheck skripta

```bash
bash scripts/healthcheck.sh http://localhost:5000
```

Proverava `/health` do 5 puta sa pauzom od 3 sekunde. Izlazni kod 0 znači da je aplikacija zdrava, a 1 da nije.

## Konfiguracija

Preko promenljivih okruženja (`.env`): `APP_PORT`, `REDIS_HOST`, `REDIS_PORT`. Primer je u `.env.example`.

## Važnije odluke

- **python:3.12-slim:** zvanična i mala slika, sa fiksiranom verzijom (ne `latest`) radi ponovljivosti.
- **Multi-stage build:** build zavisnosti su odvojene od finalne slike. Veličine:

  | Verzija | Veličina |
  |---|---|
  | Pre (single-stage) | 233 MB |
  | Posle (multi-stage) | 218 MB |

  Ušteda je mala (~6%) jer aplikacija ima malo zavisnosti, a većinu veličine čini osnovna slika.
- **Non-root korisnik:** aplikacija radi kao `appuser`, da bi se smanjila šteta u slučaju kompromitacije.
- **Redis volume:** podaci se čuvaju u `redis_data`, pa brojač preživljava `docker compose down`.
- **Redis nije izložen:** dostupan je samo unutar Docker mreže.
- **Nginx + 2 instance:** Nginx raspoređuje zahteve na dve instance (vidi se po polju `host`), a obe dele isti Redis.
- **Fiksirane verzije slika** (`redis:7-alpine`, `nginx:1.27-alpine`).

## CI pipeline

Na svaki push i pull request ka `main`: checkout, instalacija zavisnosti, linter (ruff), testovi (pytest), build Docker image-a, Trivy skeniranje,
podizanje Compose okruženja i healthcheck. Na push u `main` image se objavljuje na ghcr.io sa tagom SHA commit-a.

## Bonus zadaci

- Multi-stage build
- Objavljivanje image-a na ghcr.io (SHA tag)
- Nginx reverse proxy sa 2 instance
- Bezbednosno skeniranje (Trivy)
- Makefile

## Problemi na koje sam naišla

- **`make` nije prepoznat u PowerShell-u:** Windows ga nema podrazumevano. Instalirala sam ga preko winget-a i ponovo otvorila terminal da se učita
PATH.
- **`bash` iz PowerShell-a:** pokretao je WSL bez distribucije. Skriptu pokrećem preko Git Bash-a.
- **Docker nije mogao da pročita Dockerfile:** PowerShell `>` snima UTF-16, pa sam koristila `Out-File -Encoding ascii`.
- **Linter:** ruff je prijavio nesortirane importe, podrazumevane vrednosti u `os.getenv` koje nisu stringovi i `except Exception: pass` koji je
krio greške. Ispravila sam kod i dodala logovanje greške.
- **Trivy nije našao image:** Compose daje drugačije ime slici, pa sam image gradila posebno pod imenom `visit-counter:latest`, pre skeniranja.
- **ghcr.io odbija velika slova:** korisničko ime ima velika slova, pa se ime image-a pretvara u mala slova u pipeline-u.
- **Nginx je slao sav saobraćaj na jednu instancu:** razrešavao je ime `web` samo pri startu. Rešeno je Docker DNS resolver-om (`127.0.0.11`) i 
razrešavanjem imena pri svakom zahtevu.

## Šta bih unapredila da imam više vremena

- Kubernetes manifesti (Deployment, Service, ConfigMap) za lokalni klaster
- Healthcheck i za `web` servis u Compose-u
- Trivy da obara pipeline na HIGH/CRITICAL ranjivosti (sada samo izveštava)
- Fiksirane verzije GitHub Actions umesto `trivy-action@master`
- Više testova (`/visits`, `/health`)

## Korišćeni alati

- **Gemini:** početna postavka projekta.
- **Claude:** objašnjenja, ispravke grešaka i pomoć oko pipeline-a i Nginx-a.
- **Zvanične skripte sa predmeta ITEH (FON):** učenje Docker-a i Git-a.
- Zvanična dokumentacija (Docker, GitHub Actions, Nginx).