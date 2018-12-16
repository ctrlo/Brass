-- Convert schema '/srv/Brass/share/migrations/_source/deploy/26/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/25/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE server DROP COLUMN local_ip;

;

COMMIT;

