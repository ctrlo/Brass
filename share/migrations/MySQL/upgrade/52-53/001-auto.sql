-- Convert schema '/home/andrew-beverley/git/Brass/bin/../share/migrations/_source/deploy/52/001-auto.yml' to '/home/andrew-beverley/git/Brass/bin/../share/migrations/_source/deploy/53/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `api_key` (
  `id` integer NOT NULL auto_increment,
  `user_id` integer NOT NULL,
  `key` text NULL,
  INDEX `api_key_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `api_key_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

