-- Convert schema '/srv/Brass/share/migrations/_source/deploy/44/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/45/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE cert_location ADD COLUMN format text NULL;

;

COMMIT;

