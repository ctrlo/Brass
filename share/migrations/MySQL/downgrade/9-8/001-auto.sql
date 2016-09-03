-- Convert schema '/srv/Brass/share/migrations/_source/deploy/9/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `type` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  PRIMARY KEY (`id`)
);

;
SET foreign_key_checks=1;

;

COMMIT;

