-- Convert schema '/srv/Brass/share/migrations/_source/deploy/16/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/17/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user_topic ADD COLUMN permission integer NOT NULL,
                       ADD INDEX user_topic_idx_permission (permission),
                       ADD CONSTRAINT user_topic_fk_permission FOREIGN KEY (permission) REFERENCES permission (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

