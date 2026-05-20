-- Convert schema '/home/andrew-beverley/git/Brass/bin/../share/migrations/_source/deploy/53/001-auto.yml' to '/home/andrew-beverley/git/Brass/bin/../share/migrations/_source/deploy/52/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE api_key DROP FOREIGN KEY api_key_fk_user_id;

;
DROP TABLE api_key;

;

COMMIT;

