-- Convert schema '/srv/Brass/share/migrations/_source/deploy/20/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/21/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `docsend` (
  `id` integer NOT NULL auto_increment,
  `doc_id` integer NULL,
  `email` text NULL,
  `code` varchar(32) NULL,
  `download_time` datetime NULL,
  `download_ip_address` text NULL,
  PRIMARY KEY (`id`),
  UNIQUE `docsend_ux_code` (`code`)
);

;
SET foreign_key_checks=1;

;

COMMIT;

