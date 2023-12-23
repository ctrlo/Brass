-- Convert schema '/srv/Brass/share/migrations/_source/deploy/37/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/36/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE issue DROP FOREIGN KEY issue_fk_related_issue_id,
                  DROP INDEX issue_idx_related_issue_id,
                  DROP COLUMN corrective_action,
                  DROP COLUMN related_issue_id;

;

COMMIT;

