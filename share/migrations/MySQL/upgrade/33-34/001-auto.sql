-- Convert schema '/srv/Brass/share/migrations/_source/deploy/33/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/34/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE issue DROP COLUMN completion_time,
                  ADD COLUMN security_considerations text NULL;

;

COMMIT;

