-- Convert schema '/srv/Brass/share/migrations/_source/deploy/24/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/25/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE pw ADD COLUMN user_id integer NULL,
               ADD COLUMN publickey text NULL,
               ADD INDEX pw_idx_user_id (user_id),
               ADD CONSTRAINT pw_fk_user_id FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

