-- Convert schema '/home/abeverley/git/Brass/bin/../share/migrations/_source/deploy/52/001-auto.yml' to '/home/abeverley/git/Brass/bin/../share/migrations/_source/deploy/51/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calendar DROP COLUMN attendees_optional;

;

COMMIT;

