-- Convert schema '/srv/Brass/share/migrations/_source/deploy/11/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/12/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE issue ADD COLUMN completion_time text NULL;

;

COMMIT;

