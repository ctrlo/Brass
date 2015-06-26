-- Convert schema '/home/abeverley/git/Brass/share/migrations/_source/deploy/4/001-auto.yml' to '/home/abeverley/git/Brass/share/migrations/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE issue DROP FOREIGN KEY issue_fk_approver,
                  DROP INDEX issue_idx_approver,
                  DROP COLUMN approver,
                  DROP COLUMN security,
                  ADD COLUMN priority integer NULL,
                  ADD INDEX issue_idx_priority (priority),
                  ADD CONSTRAINT issue_fk_priority FOREIGN KEY (priority) REFERENCES priority (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE issue_status DROP FOREIGN KEY issue_status_fk_user,
                         DROP INDEX issue_status_idx_user,
                         DROP COLUMN user;

;
ALTER TABLE issue_priority DROP FOREIGN KEY issue_priority_fk_issue,
                           DROP FOREIGN KEY issue_priority_fk_priority,
                           DROP FOREIGN KEY issue_priority_fk_user;

;
DROP TABLE issue_priority;

;

COMMIT;

