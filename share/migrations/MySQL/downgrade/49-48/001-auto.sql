-- Convert schema '/home/abeverley/git/Brass/bin/../share/migrations/_source/deploy/49/001-auto.yml' to '/home/abeverley/git/Brass/bin/../share/migrations/_source/deploy/48/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE status DROP COLUMN visible,
                   DROP COLUMN identifier;

;

COMMIT;

