-- Convert schema '/srv/Brass/share/migrations/_source/deploy/12/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE issue DROP COLUMN completion_time;

;

COMMIT;

