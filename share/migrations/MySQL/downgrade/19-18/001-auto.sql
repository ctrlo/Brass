-- Convert schema '/srv/Brass/share/migrations/_source/deploy/19/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/18/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE server DROP COLUMN sudo;

;

COMMIT;

