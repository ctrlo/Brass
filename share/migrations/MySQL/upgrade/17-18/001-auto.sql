-- Convert schema '/srv/Brass/share/migrations/_source/deploy/17/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/18/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `event` (
  `id` integer NOT NULL auto_increment,
  `title` text NULL,
  `description` text NULL,
  `from` datetime NULL,
  `to` datetime NULL,
  `editor_id` integer NULL,
  `eventtype_id` integer NULL,
  `customer_id` integer NULL,
  INDEX `event_idx_customer_id` (`customer_id`),
  INDEX `event_idx_editor_id` (`editor_id`),
  INDEX `event_idx_eventtype_id` (`eventtype_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `event_fk_customer_id` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `event_fk_editor_id` FOREIGN KEY (`editor_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `event_fk_eventtype_id` FOREIGN KEY (`eventtype_id`) REFERENCES `eventtype` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
CREATE TABLE `event_person` (
  `id` integer NOT NULL auto_increment,
  `event_id` integer NULL,
  `user_id` integer NULL,
  INDEX `event_person_idx_event_id` (`event_id`),
  INDEX `event_person_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `event_person_fk_event_id` FOREIGN KEY (`event_id`) REFERENCES `event` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `event_person_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
CREATE TABLE `eventtype` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

