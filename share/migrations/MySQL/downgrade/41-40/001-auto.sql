-- Convert schema '/srv/Brass/share/migrations/_source/deploy/41/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/40/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE pw_servertype DROP FOREIGN KEY pw_servertype_fk_pw_id,
                          DROP FOREIGN KEY pw_servertype_fk_servertype_id;

;
DROP TABLE pw_servertype;

;

COMMIT;

