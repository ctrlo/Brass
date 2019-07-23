-- Convert schema '/srv/Brass/share/migrations/_source/deploy/26/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/27/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE event ADD COLUMN invoiced smallint NOT NULL DEFAULT 0;

;

COMMIT;

