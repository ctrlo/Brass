-- Convert schema '/srv/Brass/share/migrations/_source/deploy/23/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/22/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE server DROP COLUMN is_production;

;

COMMIT;

