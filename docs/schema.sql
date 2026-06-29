-- ==========================================================================
-- Shadow of Cikabayan — Cloudflare D1 Database Schema (DDL)
-- Compatible with: SQLite / Cloudflare D1
-- Normalization: Third Normal Form (3NF)
--
-- Tables:
--   1. players            — User identity from Google OAuth
--   2. character_positions — Last known position per player (1:1)
--   3. items              — Master item catalog (read-only reference data)
--   4. player_inventory   — Player ↔ Items (many-to-many with quantity)
--   5. game_states        — Key-value store for game progress flags
-- ==========================================================================

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │  1. PLAYERS                                                              │
-- │  Stores user identity data from Google OAuth.                           │
-- │  One row per authenticated user.                                        │
-- └──────────────────────────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS players (
    id              TEXT PRIMARY KEY,                    -- UUID v4, generated server-side
    google_id       TEXT NOT NULL UNIQUE,                -- Google OAuth sub (unique identifier)
    display_name    TEXT NOT NULL DEFAULT 'Irving',      -- Player display name
    email           TEXT NOT NULL UNIQUE,                -- Google email address
    avatar_url      TEXT DEFAULT '',                     -- Google profile picture URL
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),  -- ISO 8601 timestamp
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))   -- ISO 8601 timestamp
);

-- Index for fast lookup by Google ID during OAuth flow
CREATE INDEX IF NOT EXISTS idx_players_google_id ON players(google_id);


-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │  2. CHARACTER_POSITIONS                                                  │
-- │  Last known position of the player character.                           │
-- │  One-to-one relationship with players (1 player = 1 position).          │
-- │  Updated every 30 seconds by the game client auto-save.                 │
-- └──────────────────────────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS character_positions (
    id              TEXT PRIMARY KEY,                    -- UUID v4
    player_id       TEXT NOT NULL UNIQUE,                -- FK → players.id (1:1 relationship)
    map_id          TEXT NOT NULL DEFAULT 'kebun_cikabayan',  -- Current map identifier
    x_coordinate    REAL NOT NULL DEFAULT 570.0,        -- X position in pixels
    y_coordinate    REAL NOT NULL DEFAULT 321.0,        -- Y position in pixels
    direction       TEXT NOT NULL DEFAULT 'down',       -- Facing direction: up/down/left/right
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);

-- Index for fast position lookup by player
CREATE INDEX IF NOT EXISTS idx_positions_player_id ON character_positions(player_id);


-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │  3. ITEMS                                                                │
-- │  Master catalog of all items in the game.                               │
-- │  Read-only reference table; seeded once during deployment.              │
-- │  element_type matches the FORMULA_MATRIX in combat_manager.gd.          │
-- └──────────────────────────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS items (
    id              TEXT PRIMARY KEY,                    -- Unique item ID (e.g., 'reflective_mirror')
    name            TEXT NOT NULL,                       -- Display name (e.g., 'Reflective Mirror')
    description     TEXT DEFAULT '',                     -- Flavor text / tooltip
    element_type    TEXT DEFAULT 'NONE',                 -- Element: OPTICS_PHYSICS, BIO_CHEMISTRY, etc.
    is_consumable   INTEGER NOT NULL DEFAULT 1,          -- 1 = consumable, 0 = permanent/key item
    max_stack       INTEGER NOT NULL DEFAULT 99,         -- Maximum stack size in inventory
    icon_path       TEXT DEFAULT '',                     -- Path to icon sprite in R2 or bundled assets
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);


-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │  4. PLAYER_INVENTORY                                                     │
-- │  Many-to-many: which items does each player own, and how many?          │
-- │  slot_index tracks UI inventory grid position.                          │
-- └──────────────────────────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS player_inventory (
    id              TEXT PRIMARY KEY,                    -- UUID v4
    player_id       TEXT NOT NULL,                       -- FK → players.id
    item_id         TEXT NOT NULL,                       -- FK → items.id
    quantity        INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),  -- Must be positive
    slot_index      INTEGER NOT NULL DEFAULT 0,          -- Position in inventory UI grid
    acquired_at     TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id)   REFERENCES items(id)   ON DELETE RESTRICT,

    -- Prevent duplicate item entries for same player (stack instead)
    UNIQUE (player_id, item_id)
);

-- Index for fast inventory queries per player
CREATE INDEX IF NOT EXISTS idx_inventory_player_id ON player_inventory(player_id);


-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │  5. GAME_STATES                                                          │
-- │  Flexible key-value store for game progress flags.                      │
-- │  Examples:                                                               │
-- │    state_key = 'boss_defeated_kuyang',       state_value = 'true'       │
-- │    state_key = 'lab_notebook_unlocked',      state_value = 'true'       │
-- │    state_key = 'current_chapter',            state_value = '2'          │
-- │    state_key = 'satpam_terbang_encounter',   state_value = 'completed'  │
-- └──────────────────────────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS game_states (
    id              TEXT PRIMARY KEY,                    -- UUID v4
    player_id       TEXT NOT NULL,                       -- FK → players.id
    state_key       TEXT NOT NULL,                       -- Flag name (e.g., 'boss_defeated_kuyang')
    state_value     TEXT NOT NULL DEFAULT '',            -- Flag value (stored as text, parsed by app)
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,

    -- Each player can only have one value per state_key
    UNIQUE (player_id, state_key)
);

-- Index for fast flag lookup by player + key
CREATE INDEX IF NOT EXISTS idx_game_states_player_key ON game_states(player_id, state_key);


-- ==========================================================================
-- SEED DATA: Master Item Catalog
-- These items correspond to the enemy weakness matrix in PROJECT_OVERVIEW.md
-- ==========================================================================

INSERT OR IGNORE INTO items (id, name, description, element_type, is_consumable, max_stack) VALUES
    ('reflective_mirror',  'Reflective Mirror',    'Reflects optical anomalies. Effective against Satpam Terbang.',   'OPTICS_PHYSICS',    1, 10),
    ('acidic_extract',     'Acidic Extract',       'A potent bio-chemical compound. Effective against Kuyang.',       'BIO_CHEMISTRY',     1, 10),
    ('herbicide_spray',    'Herbicide Spray',      'Botanical weapon. Effective against Zombie Cikabayan.',           'BOTANY_HERBICIDE',  1, 10),
    ('aromatherapy',       'Aromatherapy Kit',     'Restores sanity. Effective against Sosok Hitam.',                 'BIO_PHARMACY',      1,  5),
    ('eco_compound',       'Eco Compound',         'Agroecological solution. Effective against Penjaga Hutan.',       'AGROECOLOGY',       1,  5),
    ('health_potion',      'Health Potion',        'Restores 30 HP.',                                                 'NONE',              1, 20),
    ('sanity_pill',        'Sanity Pill',          'Restores 20 SAN.',                                                'NONE',              1, 20),
    ('lab_notebook',       'Lab Notebook',         'Records crafting recipes discovered during exploration.',          'NONE',              0,  1);
