-- Convert schema '/srv/Brass/share/migrations/_source/deploy/3/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE permission DROP COLUMN description;

;

COMMIT;

