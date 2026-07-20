-- Convert schema '/home/andrew-beverley/git/Brass/bin/../share/migrations/_source/deploy/53/001-auto.yml' to '/home/andrew-beverley/git/Brass/bin/../share/migrations/_source/deploy/54/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE api_key ADD COLUMN kid varchar(64) NULL;

;

COMMIT;

