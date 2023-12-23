-- Convert schema '/srv/Brass/share/migrations/_source/deploy/38/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/37/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE issuetype DROP COLUMN is_other_security;

;

COMMIT;

