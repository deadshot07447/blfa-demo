# blfa-demo

A headless WordPress backend exposing GraphQL paired with a Next.js frontend.

## Repository Layout & Branches

This repository uses separate long-lived branches for the backend and frontend services:
- `backend`: Headless WordPress (Docker Compose, Nginx, MySQL, WP-CLI, WPGraphQL) and backend CI.
- `frontend`: Next.js App Router, TypeScript, vanilla CSS, and frontend CI.

Git worktrees are used to check out both branches simultaneously into separate directories:

```text
├── blfa-demo/            # Root repository (main branch, initial commit)
├── blfa-demo-backend/    # Worktree checked out on branch `backend`
└── blfa-demo-frontend/   # Worktree checked out on branch `frontend`
```

### Git Worktree Setup Commands

To set up the worktrees from scratch:

```bash
# Clone the repository
git clone <repo-url> blfa-demo
cd blfa-demo

# Create worktree for backend branch
git worktree add ../blfa-demo-backend backend

# Create worktree for frontend branch
git worktree add ../blfa-demo-frontend frontend
```

To list existing worktrees:
```bash
git worktree list
```

To remove a worktree when no longer needed:
```bash
git worktree remove ../blfa-demo-backend
git worktree remove ../blfa-demo-frontend
```

## Quick Start Overview

### 1. Backend
- Navigate to `blfa-demo-backend/`
- Run setup script: `./scripts/setup-backend.sh` (or `.\scripts\setup-backend.ps1` on Windows)
- WordPress Admin: http://localhost:9000/wp-admin
- GraphQL Endpoint: http://localhost:9000/graphql
- Healthcheck: http://localhost:9000/healthz

### 2. Frontend
- Navigate to `blfa-demo-frontend/`
- Run via Docker: `docker compose up --build -d`
- Or run locally:
  ```bash
  npm ci
  cp .env.example .env.local
  npm run dev
  ```
- Frontend Web App: http://localhost:3000
- Healthcheck: http://localhost:3000/api/health
