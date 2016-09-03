-- Convert schema '/srv/Brass/share/migrations/_source/deploy/6/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `issuetype` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  PRIMARY KEY (`id`)
);

;
SET foreign_key_checks=1;

;

COMMIT;

