-- Convert schema '/srv/Brass/share/migrations/_source/deploy/25/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/24/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE pw DROP FOREIGN KEY pw_fk_user_id,
               DROP INDEX pw_idx_user_id,
               DROP COLUMN user_id,
               DROP COLUMN publickey;

;

COMMIT;

