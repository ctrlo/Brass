-- Convert schema '/srv/Brass/share/migrations/_source/deploy/42/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/43/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `config` (
  `id` integer NOT NULL auto_increment,
  `internal_networks` text NULL,
  `smtp_relayhost` text NULL,
  PRIMARY KEY (`id`)
);

;
SET foreign_key_checks=1;

;

COMMIT;

