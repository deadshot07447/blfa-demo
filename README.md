# BLFA Demo - Backend

Headless WordPress backend exposing a GraphQL API via WPGraphQL, served by Nginx and backed by MySQL.

## Architecture

This service uses official, unmodified upstream container images without custom Dockerfiles:
- **Nginx (`nginx:1.27-alpine`)**: Public gateway on port `9000`. Serves static assets, routes `/healthz` directly, and forwards dynamic requests to WordPress via FastCGI.
- **WordPress (`wordpress:php8.2-fpm-alpine`)**: Headless PHP-FPM application.
- **MySQL (`mysql:8.0`)**: Relational database with automatic health check.
- **WP-CLI (`wordpress:cli-php8.2`)**: CLI tool under the `tools` compose profile for automated initialization and seeding.
- **Network (`blfa-network`)**: Bridge network named `blfa-network` to allow the frontend container to communicate internally.

## Endpoints

When the stack is running:
| Endpoint | URL | Description |
| :--- | :--- | :--- |
| **WordPress Admin** | [http://localhost:9000/wp-admin](http://localhost:9000/wp-admin) | WordPress administrative dashboard |
| **GraphQL Endpoint** | [http://localhost:9000/graphql](http://localhost:9000/graphql) | WPGraphQL query endpoint |
| **Health Check** | [http://localhost:9000/healthz](http://localhost:9000/healthz) | Plain text `ok` status (200) |

## Environment Variables

Configured in `.env` (copied from `.env.example`):

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `WORDPRESS_DB_NAME` | `blfa_db` | MySQL database name |
| `WORDPRESS_DB_USER` | `blfa_user` | MySQL database user |
| `WORDPRESS_DB_PASSWORD` | `CHANGE_ME_DB_PASSWORD` | MySQL user password |
| `WORDPRESS_DB_ROOT_PASSWORD` | `CHANGE_ME_ROOT_PASSWORD` | MySQL root administrative password |
| `WORDPRESS_TABLE_PREFIX` | `wp_` | Table prefix in MySQL database |
| `WORDPRESS_DEBUG` | `1` | Enable/disable WordPress debug mode |
| `WORDPRESS_PORT` | `9000` | Host port mapped to Nginx web server |
| `WORDPRESS_TITLE` | `BLFA Demo WordPress` | Site title configured during core install |
| `WORDPRESS_ADMIN_USER` | `admin` | WordPress admin username |
| `WORDPRESS_ADMIN_PASSWORD` | `adminpassword` | WordPress admin password |
| `WORDPRESS_ADMIN_EMAIL` | `admin@example.com` | WordPress admin email address |

## Getting Started

### 1. Automated Setup

Run the setup script from the backend directory:

**Linux / macOS:**
```bash
chmod +x ./scripts/setup-backend.sh
./scripts/setup-backend.sh
```

**Windows (PowerShell):**
```powershell
.\scripts\setup-backend.ps1
```

The setup script performs the following steps idempotently:
1. Copies `.env.example` to `.env` if `.env` does not already exist.
2. Starts the backend services (`docker compose up -d`).
3. Waits for the MySQL container to report healthy.
4. Uses `wp-cli` to install WordPress core (if not already installed).
5. Configures the permalink structure to `/%postname%/`.
6. Installs and activates the `wp-graphql` plugin.
7. Seeds 5 sample posts if no posts currently exist.

### 2. Manual Run

If you wish to manage containers manually:
```bash
# Start background services
docker compose up -d

# View status
docker compose ps
```

## Viewing Logs

To stream logs from all services or a specific service:
```bash
# All containers
docker compose logs -f

# Specific containers
docker compose logs -f nginx
docker compose logs -f wordpress
docker compose logs -f db
```

## Running WP-CLI Commands

To run arbitrary WP-CLI commands against the running stack:
```bash
docker compose run --rm wp-cli post list
```

## Full Reset

To stop all services and wipe all data volumes (database and uploads):
```bash
docker compose down -v
```