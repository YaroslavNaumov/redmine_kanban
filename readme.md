# Redmine Kanban Plugin

A lightweight Kanban board plugin for Redmine.

This plugin provides a simple Kanban board view for Redmine issues, allowing teams to visualize workflow by issue status.

Compatible with **Redmine 5.x**.

---

# Features

- Kanban board by issue status
- Issue cards with tracker, title, and assignee
- Project scoped board
- Lightweight and dependency-free
- Compatible with SQLite, MySQL, PostgreSQL

---

# Requirements

- Redmine >= 5.0
- Ruby >= 3.0

---

# Installation

Clone plugin into Redmine plugins directory.
cd redmine/plugins
git clone <repo> redmine_kanban


Run plugin migrations.


bundle exec rake redmine:plugins:migrate


Restart Redmine.

---

# Docker Installation

Example docker-compose:

```yaml
services:
    redmine:
    image: redmine:5.1.10
    restart: unless-stopped
    ports:
    - "8080:3000"
    volumes:
    - ./plugins:/usr/src/redmine/plugins
    - ./sqlite:/usr/src/redmine/sqlite
```

Run migrations:


docker exec redmine bundle exec rake redmine:plugins:migrate

Usage

Open a project

Click Kanban in the project menu

Issues will be grouped by status

Configuration

Issue statuses represent Kanban columns.

Example workflow:


New → ToDo → In Progress → Done

Known Limitations

No drag-and-drop support

Large projects may require pagination

Tracker colors are generated automatically

Development

Run Redmine locally with plugin mounted:


docker compose up


Plugin directory:


plugins/redmine_kanban

Contributing

Pull requests are welcome.

Please follow Redmine plugin development guidelines.