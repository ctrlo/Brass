-- Convert schema '/srv/Brass/share/migrations/_source/deploy/13/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/14/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE pw ADD COLUMN pwencrypt blob NULL;

;

COMMIT;

