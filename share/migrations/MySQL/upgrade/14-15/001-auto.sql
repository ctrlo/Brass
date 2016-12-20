-- Convert schema '/srv/Brass/share/migrations/_source/deploy/14/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/15/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `file` (
  `id` integer NOT NULL auto_increment,
  `uploaded_by` integer NOT NULL,
  `issue` integer NOT NULL,
  `datetime` datetime NULL,
  `name` text NULL,
  `mimetype` text NULL,
  `content` longblob NULL,
  INDEX `file_idx_issue` (`issue`),
  INDEX `file_idx_uploaded_by` (`uploaded_by`),
  PRIMARY KEY (`id`),
  CONSTRAINT `file_fk_issue` FOREIGN KEY (`issue`) REFERENCES `issue` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `file_fk_uploaded_by` FOREIGN KEY (`uploaded_by`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

