-- Convert schema '/srv/Brass/share/migrations/_source/deploy/41/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/42/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `docreadtype` (
  `id` integer NOT NULL auto_increment,
  `name` text NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

;
CREATE TABLE `doc_docreadtype` (
  `id` integer NOT NULL auto_increment,
  `doc_id` integer NOT NULL,
  `docreadtype_id` integer NOT NULL,
  INDEX `doc_docreadtype_idx_docreadtype_id` (`docreadtype_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `doc_docreadtype_fk_docreadtype_id` FOREIGN KEY (`docreadtype_id`) REFERENCES `docreadtype` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
CREATE TABLE `user_docread` (
  `id` integer NOT NULL auto_increment,
  `user_id` integer NOT NULL,
  `doc_id` integer NOT NULL,
  `datetime` datetime NULL,
  `ip_address` text NULL,
  INDEX `user_docread_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_docread_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
CREATE TABLE `user_docreadtype` (
  `id` integer NOT NULL auto_increment,
  `user_id` integer NOT NULL,
  `docreadtype_id` integer NOT NULL,
  INDEX `user_docreadtype_idx_docreadtype_id` (`docreadtype_id`),
  INDEX `user_docreadtype_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_docreadtype_fk_docreadtype_id` FOREIGN KEY (`docreadtype_id`) REFERENCES `docreadtype` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_docreadtype_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

