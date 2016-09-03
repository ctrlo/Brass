-- Convert schema '/srv/Brass/share/migrations/_source/deploy/9/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `cert` (
  `id` integer NOT NULL auto_increment,
  `content` text NULL,
  `cn` varchar(45) NULL,
  `type` varchar(45) NULL,
  `expiry` date NULL,
  `usedby` varchar(45) NULL,
  `filename` text NULL,
  `file_user` text NULL,
  `file_group` text NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

;
CREATE TABLE `cert_use` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

;
CREATE TABLE `domain` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(45) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

;
CREATE TABLE `pw` (
  `id` integer NOT NULL auto_increment,
  `server_id` integer NULL,
  `uad_id` integer NULL,
  `username` varchar(45) NULL,
  `password` varchar(45) NULL,
  `type` varchar(128) NULL,
  `last_changed` datetime NULL,
  INDEX `pw_idx_server_id` (`server_id`),
  INDEX `pw_idx_uad_id` (`uad_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `pw_fk_server_id` FOREIGN KEY (`server_id`) REFERENCES `server` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `pw_fk_uad_id` FOREIGN KEY (`uad_id`) REFERENCES `uad` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
CREATE TABLE `server` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  `domain_id` integer NULL,
  `update_datetime` datetime NULL,
  `update_result` text NULL,
  `restart_required` text NULL,
  `os_version` varchar(128) NULL,
  `backup_verify` text NULL,
  `notes` text NULL,
  INDEX `server_idx_domain_id` (`domain_id`),
  PRIMARY KEY (`id`),
  UNIQUE `name_UNIQUE` (`name`),
  CONSTRAINT `server_fk_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `domain` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
CREATE TABLE `server_cert` (
  `id` integer NOT NULL auto_increment,
  `server_id` integer NOT NULL,
  `cert_id` integer NOT NULL,
  `type` varchar(45) NULL,
  `use` integer NULL,
  INDEX `server_cert_idx_cert_id` (`cert_id`),
  INDEX `server_cert_idx_server_id` (`server_id`),
  INDEX `server_cert_idx_use` (`use`),
  PRIMARY KEY (`id`),
  CONSTRAINT `server_cert_fk_cert_id` FOREIGN KEY (`cert_id`) REFERENCES `cert` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `server_cert_fk_server_id` FOREIGN KEY (`server_id`) REFERENCES `server` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `server_cert_fk_use` FOREIGN KEY (`use`) REFERENCES `cert_use` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
CREATE TABLE `server_servertype` (
  `id` integer NOT NULL auto_increment,
  `server_id` integer NOT NULL,
  `servertype_id` integer NOT NULL,
  INDEX `server_servertype_idx_server_id` (`server_id`),
  INDEX `server_servertype_idx_servertype_id` (`servertype_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `server_servertype_fk_server_id` FOREIGN KEY (`server_id`) REFERENCES `server` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `server_servertype_fk_servertype_id` FOREIGN KEY (`servertype_id`) REFERENCES `servertype` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
CREATE TABLE `servertype` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(45) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

;
CREATE TABLE `site` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  `server_id` integer NULL,
  INDEX `site_idx_server_id` (`server_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `site_fk_server_id` FOREIGN KEY (`server_id`) REFERENCES `server` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
CREATE TABLE `uad` (
  `id` integer NOT NULL auto_increment,
  `name` text NULL,
  `owner` integer NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

