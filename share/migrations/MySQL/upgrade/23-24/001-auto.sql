-- Convert schema '/srv/Brass/share/migrations/_source/deploy/23/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/24/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `user_servertype` (
  `id` integer NOT NULL auto_increment,
  `user` integer NOT NULL,
  `servertype` integer NOT NULL,
  INDEX `user_servertype_idx_servertype` (`servertype`),
  INDEX `user_servertype_idx_user` (`user`),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_servertype_fk_servertype` FOREIGN KEY (`servertype`) REFERENCES `servertype` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_servertype_fk_user` FOREIGN KEY (`user`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

