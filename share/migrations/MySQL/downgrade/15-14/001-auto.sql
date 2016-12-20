-- Convert schema '/srv/Brass/share/migrations/_source/deploy/15/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/14/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE file DROP FOREIGN KEY file_fk_issue,
                 DROP FOREIGN KEY file_fk_uploaded_by;

;
DROP TABLE file;

;

COMMIT;

