-- Convert schema '/srv/Brass/share/migrations/_source/deploy/11/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE server_pw DROP FOREIGN KEY server_pw_fk_pw_id,
                      DROP FOREIGN KEY server_pw_fk_server_id;

;
DROP TABLE server_pw;

;

COMMIT;

