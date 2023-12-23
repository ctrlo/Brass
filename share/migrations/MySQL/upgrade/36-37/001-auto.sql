-- Convert schema '/srv/Brass/share/migrations/_source/deploy/36/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/37/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE issue ADD COLUMN corrective_action text NULL,
                  ADD COLUMN related_issue_id integer NULL,
                  ADD INDEX issue_idx_related_issue_id (related_issue_id),
                  ADD CONSTRAINT issue_fk_related_issue_id FOREIGN KEY (related_issue_id) REFERENCES issue (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

