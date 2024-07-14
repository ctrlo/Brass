-- Convert schema '/srv/Brass/share/migrations/_source/deploy/40/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/41/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `pw_servertype` (
  `id` integer NOT NULL auto_increment,
  `servertype_id` integer NULL,
  `pw_id` integer NULL,
  INDEX `pw_servertype_idx_pw_id` (`pw_id`),
  INDEX `pw_servertype_idx_servertype_id` (`servertype_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `pw_servertype_fk_pw_id` FOREIGN KEY (`pw_id`) REFERENCES `pw` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `pw_servertype_fk_servertype_id` FOREIGN KEY (`servertype_id`) REFERENCES `servertype` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

