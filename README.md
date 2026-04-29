# Deskbolic

Deskbolic is a comprehensive customer communication platform featuring a shared inbox, help center, and a live chat widget. It is built with Rails 8, AnyCable for real-time synchronization, and a modern frontend stack.

## Project Structure

The repository is organized into several key components:

- **`core`**: A shared Rails Engine containing the core business logic, models, and shared services (e.g., seeding, message creation).
- **`deskbolic`**: The main user dashboard application for agents, accounts, and affiliates to manage conversations and settings.
- **`portal`**: The public-facing Help Center/Knowledge Base application.
- **`widget`**: The live chat widget backend and frontend assets that get embedded on customer websites.

---

## Prerequisites

Ensure you have the following installed on your system:

- **Ruby 3.4.1** (Managed via [rvm](https://rvm.io/) or [rbenv](https://github.com/rbenv/rbenv))
- **Node.js 20.x or 21.x**
- **Yarn** (Classic or Berry)
- **PostgreSQL** (v14+)
- **Redis** (Used for Sidekiq and ActionCable/AnyCable)
- **AnyCable-Go**: The WebSocket server for AnyCable.
- **ElasticSearch**: Required for search functionality (Searchkick).
- **Docker**: Recommended for running services like Redis and ElasticSearch easily.

---

## Installation & Setup

### 1. Clone the Repository
```bash
git clone git@github.com:deskbolic/deskbolic.git
cd deskbolic
```

### 2. Ruby & Node Setup
If you are using RVM:
```bash
rvm install 3.4.1
rvm use 3.4.1
```
Install JS dependencies:
```bash
# Run this in each application directory (core, deskbolic, portal, widget)
yarn install
```

### 3. Configuration
Each application has its own encrypted credentials. You must create the `credentials.yml.enc` files from the provided samples:

```bash
cp core/config/credentials.yml.enc.sample core/config/credentials.yml.enc
cp deskbolic/config/credentials.yml.enc.sample deskbolic/config/credentials.yml.enc
cp portal/config/credentials.yml.enc.sample portal/config/credentials.yml.enc
cp widget/config/credentials.yml.enc.sample widget/config/credentials.yml.enc
```
*Note: You will also need the corresponding `master.key` for each application to decrypt the credentials.*

### 4. Database Setup
The applications share a database structure. Initialize the database from the `deskbolic` (admin) directory:

```bash
cd deskbolic
bundle install
bin/rails db:create
bin/rails db:migrate
```

### 5. Seeding Data
To set up a functional development environment with test agents, widgets, and help center articles, use the shared seeders from the `deskbolic` directory:

```bash
cd deskbolic
bin/rails runner "Seeds::WebWidgetSeeder.seed"
```
This will:
- Create a test Account and Agents (with random avatars).
- Configure a Web Widget and Inbox.
- Seed Help Center categories and articles.
- Create a test customer and conversation.

---

## Running the Applications

To run the full suite, you will need multiple terminal windows or a tool like `tmux`.

### 1. Start External Services
Ensure PostgreSQL, Redis, and ElasticSearch are running.
Start `anycable-go`:
```bash
anycable-go --host=localhost --port=8080
```

### 2. Start Project Components
Each component should run on a dedicated port to avoid conflicts:

**User Dashboard (deskbolic)** - [http://localhost:3000](http://localhost:3000)
```bash
cd deskbolic
PORT=3000 bin/dev
```

**Chat Widget (widget)** - [http://localhost:3001](http://localhost:3001)
```bash
cd widget
PORT=3001 bin/dev
```

**Help Center (portal)** - [http://localhost:3002](http://localhost:3002)
```bash
cd portal
PORT=3002 bin/dev
```

The `bin/dev` command uses `Procfile.dev` to start the Rails server, AnyCable RPC server, and JS/CSS build watchers.

---

## Environment & Tooling

### Ruby Version Management
We use **Ruby 3.4.1**. Ensure your local manager is configured:
- **RVM**: `rvm use 3.4.1` (or `rvm install 3.4.1` if missing)
- **rbenv**: `rbenv local 3.4.1`

### JavaScript & Assets
- **Yarn**: Use `yarn install` in each directory.
- **Builds**: Assets are compiled to `app/assets/builds`. If you encounter UI issues, try running `yarn build` and `yarn build:css` manually.

---

## Deployment & Production
- Action Cable: Use `anycable` as the adapter in `config/cable.yml`.
- WebSockets: `AnyCable-Go` handles the client connections.
- Asset Pipeline: Uses `propshaft` for modern asset management.

---

## License
Techbolic Solutions (Private) Limited. All rights reserved.
