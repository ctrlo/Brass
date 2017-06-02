-- Convert schema '/srv/Brass/share/migrations/_source/deploy/19/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/20/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `issue_tag` (
  `id` integer NOT NULL auto_increment,
  `issue` integer NOT NULL,
  `tag` integer NOT NULL,
  INDEX `issue_tag_idx_issue` (`issue`),
  INDEX `issue_tag_idx_tag` (`tag`),
  PRIMARY KEY (`id`),
  CONSTRAINT `issue_tag_fk_issue` FOREIGN KEY (`issue`) REFERENCES `issue` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `issue_tag_fk_tag` FOREIGN KEY (`tag`) REFERENCES `tag` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
CREATE TABLE `tag` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

