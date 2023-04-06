-- Convert schema '/srv/Brass/share/migrations/_source/deploy/31/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/32/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `calendar` (
  `id` integer NOT NULL auto_increment,
  `start` datetime NULL,
  `end` datetime NULL,
  `sequence` integer NOT NULL DEFAULT 0,
  `description` text NULL,
  `location` text NULL,
  `attendees` text NULL,
  `html` text NULL,
  `user_id` integer NULL,
  INDEX `calendar_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `calendar_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

