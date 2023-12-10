-- Convert schema '/srv/Brass/share/migrations/_source/deploy/34/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/35/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `cert_location` (
  `id` integer NOT NULL auto_increment,
  `cert_id` integer NOT NULL,
  `filename_cert` text NULL,
  `filename_key` text NULL,
  `filename_ca` text NULL,
  `file_user` text NULL,
  `file_group` text NULL,
  INDEX `cert_location_idx_cert_id` (`cert_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `cert_location_fk_cert_id` FOREIGN KEY (`cert_id`) REFERENCES `cert` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
CREATE TABLE `cert_location_use` (
  `id` integer NOT NULL auto_increment,
  `cert_location_id` integer NOT NULL,
  `use_id` integer NOT NULL,
  INDEX `cert_location_use_idx_cert_location_id` (`cert_location_id`),
  INDEX `cert_location_use_idx_use_id` (`use_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `cert_location_use_fk_cert_location_id` FOREIGN KEY (`cert_location_id`) REFERENCES `cert_location` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `cert_location_use_fk_use_id` FOREIGN KEY (`use_id`) REFERENCES `cert_use` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE cert ADD COLUMN description text NULL,
                 ADD COLUMN content_cert text NULL,
                 ADD COLUMN content_key text NULL,
                 ADD COLUMN content_ca text NULL;

;

COMMIT;

