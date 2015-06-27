-- Convert schema '/home/abeverley/git/Brass/share/migrations/_source/deploy/5/001-auto.yml' to '/home/abeverley/git/Brass/share/migrations/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user_project DROP FOREIGN KEY user_project_fk_project,
                         DROP FOREIGN KEY user_project_fk_user;

;
DROP TABLE user_project;

;

COMMIT;

