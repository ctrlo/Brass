-- Convert schema '/srv/Brass/share/migrations/_source/deploy/21/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/22/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE docsend ADD COLUMN created datetime NULL;

;

COMMIT;

