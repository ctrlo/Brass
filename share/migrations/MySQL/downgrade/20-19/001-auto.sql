-- Convert schema '/srv/Brass/share/migrations/_source/deploy/20/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/19/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE issue_tag DROP FOREIGN KEY issue_tag_fk_issue,
                      DROP FOREIGN KEY issue_tag_fk_tag;

;
DROP TABLE issue_tag;

;
DROP TABLE tag;

;

COMMIT;

