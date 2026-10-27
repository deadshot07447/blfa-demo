# BLFA Demo - Frontend

Next.js App Router frontend for the headless WordPress backend, styled with minimal vanilla CSS and fetching data via WPGraphQL.

## Architecture

- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Styling**: Vanilla CSS (single global stylesheet, system fonts, zero UI frameworks or animations)
- **Data Fetching**: Plain `fetch` querying WPGraphQL with 60-second revalidation (`revalidate: 60`)
- **HTML Sanitization**: WordPress post HTML is rendered safely using `sanitize-html`
- **Output**: Next.js `standalone` mode for containerization

## Endpoints & URLs

| Endpoint | URL | Description |
| :--- | :--- | :--- |
| **Home Page** | [http://localhost:3000](http://localhost:3000) | Lists latest published WordPress posts |
| **Post Detail** | `http://localhost:3000/posts/[slug]` | Individual post page |
| **Health Check** | [http://localhost:3000/api/health](http://localhost:3000/api/health) | Returns JSON `{"status":"ok"}` |

## Environment Variables

Configured in `.env.local` (local host development) or `.env` / compose (Docker):

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `NEXT_PUBLIC_WORDPRESS_API_URL` | `http://localhost:9000/graphql` | Browser-facing GraphQL URL, baked into client builds |
| `WORDPRESS_INTERNAL_API_URL` | `http://nginx/graphql` | Internal Docker GraphQL URL used by server-side fetch |
| `PORT` | `3000` | Application HTTP port |

## Running Locally on Host

Make sure the backend is running at `http://localhost:9000` before starting:

```bash
# 1. Install dependencies
npm ci

# 2. Configure local environment
cp .env.example .env.local

# Note: On host, set WORDPRESS_INTERNAL_API_URL to http://localhost:9000/graphql in .env.local

# 3. Start development server
npm run dev
```

Visit [http://localhost:3000](http://localhost:3000).

## Running in Docker

Ensure the backend services are running and the `blfa-network` network exists (started from the backend worktree):

```bash
# Build and start container in background
docker compose up --build -d

# View status and health
docker compose ps

# Follow logs
docker compose logs -f frontend

# Stop container
docker compose down
```

## Linting and Building

```bash
# Run ESLint
npm run lint

# Create production build
npm run build
```