-- Convert schema '/home/abeverley/git/Brass/share/migrations/_source/deploy/5/001-auto.yml' to '/home/abeverley/git/Brass/share/migrations/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE comment DROP FOREIGN KEY comment_fk_id,
                    ADD INDEX comment_idx_issue (issue),
                    ADD CONSTRAINT comment_fk_issue FOREIGN KEY (issue) REFERENCES issue (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

