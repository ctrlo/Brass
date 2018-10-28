-- Convert schema '/srv/Brass/share/migrations/_source/deploy/24/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/23/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user_servertype DROP FOREIGN KEY user_servertype_fk_servertype,
                            DROP FOREIGN KEY user_servertype_fk_user;

;
DROP TABLE user_servertype;

;

COMMIT;

