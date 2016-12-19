-- Convert schema '/srv/Brass/share/migrations/_source/deploy/12/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `user_topic` (
  `id` integer NOT NULL auto_increment,
  `user` integer NOT NULL,
  `topic` integer NOT NULL,
  INDEX `user_topic_idx_user` (`user`),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_topic_fk_user` FOREIGN KEY (`user`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

