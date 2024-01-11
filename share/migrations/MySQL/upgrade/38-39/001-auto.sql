-- Convert schema '/srv/Brass/share/migrations/_source/deploy/38/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/39/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE issue DROP COLUMN security;

;

COMMIT;

