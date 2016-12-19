-- Convert schema '/srv/Brass/share/migrations/_source/deploy/13/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/12/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user_topic DROP FOREIGN KEY user_topic_fk_user;

;
DROP TABLE user_topic;

;

COMMIT;

