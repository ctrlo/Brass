-- Convert schema '/srv/Brass/share/migrations/_source/deploy/10/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `server_pw` (
  `id` integer NOT NULL auto_increment,
  `server_id` integer NULL,
  `pw_id` integer NULL,
  INDEX `server_pw_idx_pw_id` (`pw_id`),
  INDEX `server_pw_idx_server_id` (`server_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `server_pw_fk_pw_id` FOREIGN KEY (`pw_id`) REFERENCES `pw` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `server_pw_fk_server_id` FOREIGN KEY (`server_id`) REFERENCES `server` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

