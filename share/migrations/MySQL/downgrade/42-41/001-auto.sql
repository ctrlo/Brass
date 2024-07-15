-- Convert schema '/srv/Brass/share/migrations/_source/deploy/42/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/41/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE doc_docreadtype DROP FOREIGN KEY doc_docreadtype_fk_docreadtype_id;

;
DROP TABLE doc_docreadtype;

;
DROP TABLE docreadtype;

;
ALTER TABLE user_docread DROP FOREIGN KEY user_docread_fk_user_id;

;
DROP TABLE user_docread;

;
ALTER TABLE user_docreadtype DROP FOREIGN KEY user_docreadtype_fk_docreadtype_id,
                             DROP FOREIGN KEY user_docreadtype_fk_user_id;

;
DROP TABLE user_docreadtype;

;

COMMIT;

