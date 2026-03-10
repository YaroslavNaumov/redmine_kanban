# Redmine Kanban Plugin

A lightweight Kanban plugin for Redmine with drag-and-drop, member filtering, and flexible column display settings.

Compatible with **Redmine 5.x**.

---

## Features

- Kanban board organised by issue statuses
- Drag-and-drop issue movement between columns (recorded in issue history)
- Filter issues by project member
- Issue cards showing tracker, priority, assignee, progress, and time estimates
- Color-coded priority indicator on each card
- Closed statuses displayed separately with visual distinction
- Option to hide columns with closed statuses
- Per-project card display settings
- Horizontal scroll when the board has many columns
- Vertical scroll within each column
- Compatible with SQLite, MySQL, PostgreSQL

---

## Requirements

- Redmine >= 5.0
- Ruby >= 3.0

---

## Installation

Clone the plugin into the Redmine plugins directory:

```bash
cd redmine/plugins
git clone https://github.com/YaroslavNaumov/redmine_kanban
```

Run migrations:

```bash
bundle exec rake redmine:plugins:migrate
```

Restart Redmine.

---

## Docker Installation

Example `docker-compose.yml`:

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

```bash
docker exec redmine bundle exec rake redmine:plugins:migrate
docker compose restart redmine
```

---

## Usage

1. Open a project
2. Click **Kanban** in the project menu
3. Issues are grouped by status into columns

### Member Filter

The board header contains a **Member** dropdown that limits displayed issues to a specific project member. Selecting **All members** resets the filter.

### Moving Issues

Cards can be dragged between columns. Each move is recorded in the issue history as a status change. The role must have both the **Move issues on board** and **Edit issues** permissions for this to work.

---

## Board Settings

Navigate to **Kanban → Kanban settings** (the ⚙ icon in the top-right corner of the board).

### Board Options

| Setting | Description |
|---|---|
| Name | Board name |
| Description | Board description |
| Enabled | Enable or disable the module for this project |

### Card Display

| Setting | Default | Description |
|---|---|---|
| Show assignee | ✓ | Displays the assigned user's name and avatar |
| Show priority | ✓ | Displays the priority label on the card |
| Show estimated hours | ✓ | Displays the estimated time for the issue |
| Show spent hours | ✓ | Displays the actual logged time for the issue |

### Column Settings

| Setting | Default | Description |
|---|---|---|
| Hide closed-status columns | ✗ | Removes columns whose status is marked as closed in Redmine's status settings |

---

## Permissions

Configured in **Administration → Roles and permissions** for each project role.

| Permission | Description |
|---|---|
| View kanban board | Access the board and view issues |
| Move issues on board | Drag-and-drop cards between columns |
| Manage kanban settings | Edit board settings for the project |

---

## Project Structure

```
redmine_kanban/
├── app/
│   ├── controllers/
│   │   └── kanban_controller.rb       # Main controller
│   └── views/
│       ├── kanban/
│       │   ├── index.html.erb         # Board view
│       │   ├── settings.html.erb      # Settings page
│       │   └── _issue_card.html.erb   # Issue card partial
│       └── settings/
│           └── _kanban_settings.html.erb  # Global plugin settings
├── assets/
│   ├── javascripts/kanban.js          # Drag-and-drop, AJAX
│   └── stylesheets/kanban.css         # Board styles
├── config/
│   ├── locales/
│   │   ├── ru.yml
│   │   └── en.yml
│   └── routes.rb
├── db/migrate/
│   └── 20240101000000_create_kanban_boards.rb
├── lib/
│   ├── kanban_board.rb                # Board model (business logic)
│   └── redmine_kanban/hooks.rb        # Redmine hooks
└── init.rb                            # Plugin registration
```

---

## Known Limitations

- No pagination — columns with many issues scroll vertically
- Tracker colors are generated automatically

---

## Development

Run Redmine locally with the plugin mounted:

```bash
docker compose up
```

Plugin directory: `plugins/redmine_kanban`

---

## Contributing

Pull requests are welcome. Please follow the official [Redmine plugin development guidelines](https://www.redmine.org/projects/redmine/wiki/Plugin_Tutorial).
