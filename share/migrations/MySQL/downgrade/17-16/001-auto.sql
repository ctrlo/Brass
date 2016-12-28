-- Convert schema '/srv/Brass/share/migrations/_source/deploy/17/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/16/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user_topic DROP FOREIGN KEY user_topic_fk_permission,
                       DROP INDEX user_topic_idx_permission,
                       DROP COLUMN permission;

;

COMMIT;

