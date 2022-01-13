-- Convert schema '/srv/Brass/share/migrations/_source/deploy/30/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/29/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user DROP COLUMN api_key;

;

COMMIT;

