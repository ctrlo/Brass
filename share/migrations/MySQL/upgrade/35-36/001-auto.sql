-- Convert schema '/srv/Brass/share/migrations/_source/deploy/35/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/36/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE issue ADD COLUMN rca text NULL;

;
ALTER TABLE issuetype ADD COLUMN identifier varchar(32) NULL,
                      ADD COLUMN is_vulnerability smallint NOT NULL DEFAULT 0,
                      ADD COLUMN is_breach smallint NOT NULL DEFAULT 0,
                      ADD COLUMN is_audit smallint NOT NULL DEFAULT 0;

;

COMMIT;

