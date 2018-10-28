-- Convert schema '/srv/Brass/share/migrations/_source/deploy/22/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/23/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE server ADD COLUMN is_production smallint NOT NULL DEFAULT 0;

;

COMMIT;

