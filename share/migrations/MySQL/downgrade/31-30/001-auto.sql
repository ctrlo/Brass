-- Convert schema '/srv/Brass/share/migrations/_source/deploy/31/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/30/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE server DROP COLUMN metadata;

;

COMMIT;

