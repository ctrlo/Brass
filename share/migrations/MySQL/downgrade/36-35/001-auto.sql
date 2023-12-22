-- Convert schema '/srv/Brass/share/migrations/_source/deploy/36/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/35/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE issue DROP COLUMN rca;

;
ALTER TABLE issuetype DROP COLUMN identifier,
                      DROP COLUMN is_vulnerability,
                      DROP COLUMN is_breach,
                      DROP COLUMN is_audit;

;

COMMIT;

