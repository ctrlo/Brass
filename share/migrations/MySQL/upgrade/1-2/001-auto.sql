-- Convert schema '/home/abeverley/git/Brass/share/migrations/_source/deploy/1/001-auto.yml' to '/home/abeverley/git/Brass/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user ADD COLUMN password varchar(128) NULL;

;

COMMIT;

