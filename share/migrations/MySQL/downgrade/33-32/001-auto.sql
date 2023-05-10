-- Convert schema '/srv/Brass/share/migrations/_source/deploy/33/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/32/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE uad DROP COLUMN serial,
                DROP COLUMN purchased;

;

COMMIT;

