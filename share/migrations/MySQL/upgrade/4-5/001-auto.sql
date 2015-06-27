-- Convert schema '/home/abeverley/git/Brass/share/migrations/_source/deploy/4/001-auto.yml' to '/home/abeverley/git/Brass/share/migrations/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `user_project` (
  `id` integer NOT NULL auto_increment,
  `user` integer NOT NULL,
  `project` integer NOT NULL,
  INDEX `user_project_idx_project` (`project`),
  INDEX `user_project_idx_user` (`user`),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_project_fk_project` FOREIGN KEY (`project`) REFERENCES `project` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_project_fk_user` FOREIGN KEY (`user`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

