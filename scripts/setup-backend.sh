#!/usr/bin/env bash
set -euo pipefail

# Navigate to backend root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

# 1. Copy .env.example to .env if .env does not exist
if [ ! -f .env ]; then
  echo "Copying .env.example to .env..."
  cp .env.example .env
fi

# Export environment variables from .env
set -a
[ -f .env ] && . .env
set +a

# 2. Start containers with docker compose
echo "Ensuring src/wordpress directory exists..."
mkdir -p src/wordpress
echo "Starting Docker Compose services..."
docker compose up -d

# 3. Wait until the db container reports healthy
echo "Waiting for database container to report healthy..."
timeout=120
while true; do
  STATUS=$(docker compose ps db --format '{{.Health}}' 2>/dev/null || true)
  if [[ "$STATUS" == *"healthy"* ]]; then
    echo "Database is healthy!"
    break
  fi
  sleep 2
  timeout=$((timeout - 2))
  if [ $timeout -le 0 ]; then
    echo "Error: Database failed to become healthy within timeout."
    docker compose logs db
    exit 1
  fi
done

# Wait for WordPress files and wp-config.php to initialize
echo "Waiting for WordPress files and wp-config.php to initialize..."
wp_timeout=60
while [ ! -f src/wordpress/wp-config.php ]; do
  sleep 2
  wp_timeout=$((wp_timeout - 2))
  if [ $wp_timeout -le 0 ]; then
    echo "Error: WordPress files failed to initialize."
    docker compose logs wordpress
    exit 1
  fi
done

# 4. Use wp-cli to install WordPress core
echo "Checking WordPress installation..."
if docker compose run --rm wp-cli wp core is-installed >/dev/null 2>&1; then
  echo "WordPress core is already installed."
else
  echo "Installing WordPress core..."
  docker compose run --rm wp-cli wp core install \
    --url="http://localhost:${WORDPRESS_PORT:-9000}" \
    --title="${WORDPRESS_TITLE:-BLFA Demo WordPress}" \
    --admin_user="${WORDPRESS_ADMIN_USER:-admin}" \
    --admin_password="${WORDPRESS_ADMIN_PASSWORD:-adminpassword}" \
    --admin_email="${WORDPRESS_ADMIN_EMAIL:-admin@example.com}" \
    --skip-email
fi

# 5. Set permalinks to /%postname%/
echo "Setting permalinks to /%postname%/..."
docker compose run --rm wp-cli wp rewrite structure '/%postname%/' --hard

# 6. Install and activate WPGraphQL plugin via WP-CLI
echo "Checking WPGraphQL plugin..."
if docker compose run --rm wp-cli wp plugin is-installed wp-graphql >/dev/null 2>&1; then
  echo "WPGraphQL plugin is already installed. Ensuring active..."
  docker compose run --rm wp-cli wp plugin activate wp-graphql
else
  echo "Installing and activating WPGraphQL plugin..."
  docker compose run --rm wp-cli wp plugin install wp-graphql --activate
fi

# 7. Seed 5 short sample posts only if none exist
echo "Checking existing posts..."
docker compose run --rm wp-cli wp post delete 1 --force >/dev/null 2>&1 || true

POST_COUNT=$(docker compose run --rm wp-cli wp post list --post_type=post --format=count 2>/dev/null | tr -d '\r' | tail -n 1)

if [ "${POST_COUNT:-0}" -eq 0 ]; then
  echo "Seeding 5 sample posts..."
  docker compose run --rm wp-cli wp post create \
    --post_type=post \
    --post_status=publish \
    --post_title="Welcome to Headless WordPress" \
    --post_name="welcome-to-headless-wordpress" \
    --post_excerpt="An introduction to decoupling WordPress as a headless content management system." \
    --post_content="Headless WordPress separates content management from the presentation layer. By using WordPress solely as a content repository and exposing data via WPGraphQL, frontend developers gain complete freedom over the rendering stack."

  docker compose run --rm wp-cli wp post create \
    --post_type=post \
    --post_status=publish \
    --post_title="Exploring WPGraphQL Features" \
    --post_name="exploring-wpgraphql-features" \
    --post_excerpt="How GraphQL provides efficient, declarative queries for modern frontends." \
    --post_content="WPGraphQL brings GraphQL schemas to WordPress. Rather than dealing with REST API over-fetching and multiple network roundtrips, GraphQL allows clients to request exactly the fields needed in a single HTTP request."

  docker compose run --rm wp-cli wp post create \
    --post_type=post \
    --post_status=publish \
    --post_title="Building Fast Frontends with Next.js" \
    --post_name="building-fast-frontends-with-nextjs" \
    --post_excerpt="Combining Next.js App Router with headless WordPress for optimal performance." \
    --post_content="The Next.js App Router enables server-side rendering, static site generation, and incremental revalidation. Pages can fetch content directly from the internal Docker network while serving cached HTML instantly to visitors."

  docker compose run --rm wp-cli wp post create \
    --post_type=post \
    --post_status=publish \
    --post_title="Managing Clean Multi-Branch Worktrees" \
    --post_name="managing-clean-multi-branch-worktrees" \
    --post_excerpt="Organizing decoupled applications using Git worktrees for isolated development." \
    --post_content="Using Git worktrees allows frontend and backend codebases to live in separate long-lived branches within a single Git repository. Each branch retains its own independent dependencies, configurations, and CI pipelines."

  docker compose run --rm wp-cli wp post create \
    --post_type=post \
    --post_status=publish \
    --post_title="Production Readiness and Containerization" \
    --post_name="production-readiness-and-containerization" \
    --post_excerpt="Running microservices reliably using Docker Compose and Nginx reverse proxies." \
    --post_content="By orchestrating MySQL, PHP-FPM, and Nginx with isolated networks and healthchecks, the application guarantees repeatable deployments across local machines and continuous integration environments."

  echo "Seeded 5 sample posts successfully!"
else
  echo "Sample posts already exist ($POST_COUNT found). Skipping seeding."
fi

echo "Backend setup completed successfully!"