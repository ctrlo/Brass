-- Convert schema '/home/abeverley/git/Brass/bin/../share/migrations/_source/deploy/50/001-auto.yml' to '/home/abeverley/git/Brass/bin/../share/migrations/_source/deploy/51/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE priority ADD COLUMN alert_frequency integer NULL;

;

COMMIT;

