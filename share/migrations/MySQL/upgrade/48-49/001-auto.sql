-- Convert schema '/home/abeverley/git/Brass/bin/../share/migrations/_source/deploy/48/001-auto.yml' to '/home/abeverley/git/Brass/bin/../share/migrations/_source/deploy/49/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE status ADD COLUMN visible smallint NOT NULL DEFAULT 1,
                   ADD COLUMN identifier varchar(32) NULL;

;

COMMIT;

