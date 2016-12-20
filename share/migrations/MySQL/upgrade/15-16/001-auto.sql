-- Convert schema '/srv/Brass/share/migrations/_source/deploy/15/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/16/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `customer` (
  `id` integer NOT NULL auto_increment,
  `name` text NULL,
  `authnames` text NULL,
  `updated` datetime NULL,
  `updated_by` integer NOT NULL,
  INDEX `customer_idx_updated_by` (`updated_by`),
  PRIMARY KEY (`id`),
  CONSTRAINT `customer_fk_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

