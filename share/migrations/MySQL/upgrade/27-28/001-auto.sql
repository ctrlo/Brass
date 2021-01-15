-- Convert schema '/srv/Brass/share/migrations/_source/deploy/27/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/28/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `app` (
  `id` integer NOT NULL auto_increment,
  `status_last_run` datetime NULL,
  PRIMARY KEY (`id`)
);

;
SET foreign_key_checks=1;

;

COMMIT;

