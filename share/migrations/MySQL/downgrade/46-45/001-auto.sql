-- Convert schema '/srv/Brass/share/migrations/_source/deploy/46/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/45/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE servertype DROP COLUMN description;

;

COMMIT;

