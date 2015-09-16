-- Convert schema '/home/abeverley/git/Brass/share/migrations/_source/deploy/6/001-auto.yml' to '/home/abeverley/git/Brass/share/migrations/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE comment DROP FOREIGN KEY comment_fk_issue,
                    DROP INDEX comment_idx_issue,
                    ADD CONSTRAINT comment_fk_id FOREIGN KEY (id) REFERENCES issue (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

