-- Convert schema '/srv/Brass/bin/../share/migrations/_source/deploy/46/001-auto.yml' to '/srv/Brass/bin/../share/migrations/_source/deploy/47/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calendar ADD COLUMN cancelled datetime NULL;

;

COMMIT;

