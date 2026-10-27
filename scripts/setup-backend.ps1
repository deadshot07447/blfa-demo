# Navigate to backend root
Set-Location -Path (Split-Path -Parent $PSScriptRoot)

# 1. Copy .env.example to .env if .env does not exist
if (-not (Test-Path ".env")) {
    Write-Host "Copying .env.example to .env..."
    Copy-Item ".env.example" ".env"
}

# Export environment variables from .env
Get-Content .env | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        $parts = $line.Split('=', 2)
        if ($parts.Length -eq 2) {
            [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim(), "Process")
        }
    }
}

# 2. Start containers with docker compose
Write-Host "Starting Docker Compose services..."
docker compose up -d

# 3. Wait until the db container reports healthy
Write-Host "Waiting for database container to report healthy..."
$timeout = 120
$healthy = $false
while ($timeout -gt 0) {
    $status = docker compose ps db --format "{{.Health}}" 2>$null
    if ($status -match "healthy") {
        $healthy = $true
        Write-Host "Database is healthy!"
        break
    }
    Start-Sleep -Seconds 2
    $timeout -= 2
}

if (-not $healthy) {
    Write-Error "Database failed to become healthy within timeout."
    docker compose logs db
    exit 1
}

# Wait for WordPress files to initialize in volume
Write-Host "Waiting for WordPress files to initialize..."
$wpInitTimeout = 60
while ($wpInitTimeout -gt 0) {
    docker compose run --rm wp-cli core version 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        break
    }
    Start-Sleep -Seconds 2
    $wpInitTimeout -= 2
}

# 4. Use wp-cli to install WordPress core
Write-Host "Checking WordPress installation..."
docker compose run --rm wp-cli core is-installed 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "WordPress core is already installed."
} else {
    Write-Host "Installing WordPress core..."
    $wpPort = if ($env:WORDPRESS_PORT) { $env:WORDPRESS_PORT } else { "9000" }
    $wpTitle = if ($env:WORDPRESS_TITLE) { $env:WORDPRESS_TITLE } else { "BLFA Demo WordPress" }
    $wpUser = if ($env:WORDPRESS_ADMIN_USER) { $env:WORDPRESS_ADMIN_USER } else { "admin" }
    $wpPass = if ($env:WORDPRESS_ADMIN_PASSWORD) { $env:WORDPRESS_ADMIN_PASSWORD } else { "adminpassword" }
    $wpEmail = if ($env:WORDPRESS_ADMIN_EMAIL) { $env:WORDPRESS_ADMIN_EMAIL } else { "admin@example.com" }

    docker compose run --rm wp-cli core install `
        --url="http://localhost:$wpPort" `
        --title="$wpTitle" `
        --admin_user="$wpUser" `
        --admin_password="$wpPass" `
        --admin_email="$wpEmail" `
        --skip-email
}

# 5. Set permalinks to /%postname%/
Write-Host "Setting permalinks to /%postname%/..."
docker compose run --rm wp-cli rewrite structure "/%postname%/" --hard

# 6. Install and activate WPGraphQL plugin via WP-CLI
Write-Host "Checking WPGraphQL plugin..."
docker compose run --rm wp-cli plugin is-installed wp-graphql 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "WPGraphQL plugin is already installed. Ensuring active..."
    docker compose run --rm wp-cli plugin activate wp-graphql
} else {
    Write-Host "Installing and activating WPGraphQL plugin..."
    docker compose run --rm wp-cli plugin install wp-graphql --activate
}

# 7. Seed 5 short sample posts only if none exist
Write-Host "Checking existing posts..."
docker compose run --rm wp-cli post delete 1 --force 2>$null | Out-Null

$postCountOutput = (docker compose run --rm wp-cli post list --post_type=post --format=count | Select-Object -Last 1)
$postCount = 0
if ($postCountOutput) {
    [int]::TryParse($postCountOutput.Trim(), [ref]$postCount) | Out-Null
}

if ($postCount -eq 0) {
    Write-Host "Seeding 5 sample posts..."
    docker compose run --rm wp-cli post create `
        --post_type=post `
        --post_status=publish `
        --post_title="Welcome to Headless WordPress" `
        --post_name="welcome-to-headless-wordpress" `
        --post_excerpt="An introduction to decoupling WordPress as a headless content management system." `
        --post_content="Headless WordPress separates content management from the presentation layer. By using WordPress solely as a content repository and exposing data via WPGraphQL, frontend developers gain complete freedom over the rendering stack."

    docker compose run --rm wp-cli post create `
        --post_type=post `
        --post_status=publish `
        --post_title="Exploring WPGraphQL Features" `
        --post_name="exploring-wpgraphql-features" `
        --post_excerpt="How GraphQL provides efficient, declarative queries for modern frontends." `
        --post_content="WPGraphQL brings GraphQL schemas to WordPress. Rather than dealing with REST API over-fetching and multiple network roundtrips, GraphQL allows clients to request exactly the fields needed in a single HTTP request."

    docker compose run --rm wp-cli post create `
        --post_type=post `
        --post_status=publish `
        --post_title="Building Fast Frontends with Next.js" `
        --post_name="building-fast-frontends-with-nextjs" `
        --post_excerpt="Combining Next.js App Router with headless WordPress for optimal performance." `
        --post_content="The Next.js App Router enables server-side rendering, static site generation, and incremental revalidation. Pages can fetch content directly from the internal Docker network while serving cached HTML instantly to visitors."

    docker compose run --rm wp-cli post create `
        --post_type=post `
        --post_status=publish `
        --post_title="Managing Clean Multi-Branch Worktrees" `
        --post_name="managing-clean-multi-branch-worktrees" `
        --post_excerpt="Organizing decoupled applications using Git worktrees for isolated development." `
        --post_content="Using Git worktrees allows frontend and backend codebases to live in separate long-lived branches within a single Git repository. Each branch retains its own independent dependencies, configurations, and CI pipelines."

    docker compose run --rm wp-cli post create `
        --post_type=post `
        --post_status=publish `
        --post_title="Production Readiness and Containerization" `
        --post_name="production-readiness-and-containerization" `
        --post_excerpt="Running microservices reliably using Docker Compose and Nginx reverse proxies." `
        --post_content="By orchestrating MySQL, PHP-FPM, and Nginx with isolated networks and healthchecks, the application guarantees repeatable deployments across local machines and continuous integration environments."

    Write-Host "Seeded 5 sample posts successfully!"
} else {
    Write-Host "Sample posts already exist ($postCount found). Skipping seeding."
}

Write-Host "Backend setup completed successfully!"