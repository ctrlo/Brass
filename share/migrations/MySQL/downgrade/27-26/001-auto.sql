-- Convert schema '/srv/Brass/share/migrations/_source/deploy/27/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/26/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE event DROP COLUMN invoiced;

;

COMMIT;

