-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Tue Dec 20 11:07:16 2016
-- 
;
SET foreign_key_checks=0;
--
-- Table: `cert`
--
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
--
-- Table: `cert_use`
--
CREATE TABLE `cert_use` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `comment`
--
CREATE TABLE `comment` (
  `id` integer NOT NULL auto_increment,
  `author` integer NOT NULL,
  `issue` integer NOT NULL,
  `datetime` datetime NULL,
  `text` text NULL,
  INDEX `comment_idx_author` (`author`),
  INDEX `comment_idx_issue` (`issue`),
  PRIMARY KEY (`id`),
  CONSTRAINT `comment_fk_author` FOREIGN KEY (`author`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `comment_fk_issue` FOREIGN KEY (`issue`) REFERENCES `issue` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `domain`
--
CREATE TABLE `domain` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(45) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `file`
--
CREATE TABLE `file` (
  `id` integer NOT NULL auto_increment,
  `uploaded_by` integer NOT NULL,
  `issue` integer NOT NULL,
  `datetime` datetime NULL,
  `name` text NULL,
  `mimetype` text NULL,
  `content` longblob NULL,
  INDEX `file_idx_issue` (`issue`),
  INDEX `file_idx_uploaded_by` (`uploaded_by`),
  PRIMARY KEY (`id`),
  CONSTRAINT `file_fk_issue` FOREIGN KEY (`issue`) REFERENCES `issue` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `file_fk_uploaded_by` FOREIGN KEY (`uploaded_by`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `issue`
--
CREATE TABLE `issue` (
  `id` integer NOT NULL auto_increment,
  `title` text NULL,
  `description` text NULL,
  `completion_time` text NULL,
  `type` integer NULL,
  `author` integer NULL,
  `owner` integer NULL,
  `approver` integer NULL,
  `reference` varchar(128) NULL,
  `project` integer NULL,
  `security` smallint NOT NULL DEFAULT 0,
  INDEX `issue_idx_approver` (`approver`),
  INDEX `issue_idx_author` (`author`),
  INDEX `issue_idx_owner` (`owner`),
  INDEX `issue_idx_project` (`project`),
  INDEX `issue_idx_type` (`type`),
  PRIMARY KEY (`id`),
  CONSTRAINT `issue_fk_approver` FOREIGN KEY (`approver`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `issue_fk_author` FOREIGN KEY (`author`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `issue_fk_owner` FOREIGN KEY (`owner`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `issue_fk_project` FOREIGN KEY (`project`) REFERENCES `project` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `issue_fk_type` FOREIGN KEY (`type`) REFERENCES `issuetype` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `issue_priority`
--
CREATE TABLE `issue_priority` (
  `id` integer NOT NULL auto_increment,
  `issue` integer NOT NULL,
  `priority` integer NOT NULL,
  `datetime` datetime NULL,
  `user` integer NULL,
  INDEX `issue_priority_idx_issue` (`issue`),
  INDEX `issue_priority_idx_priority` (`priority`),
  INDEX `issue_priority_idx_user` (`user`),
  PRIMARY KEY (`id`),
  CONSTRAINT `issue_priority_fk_issue` FOREIGN KEY (`issue`) REFERENCES `issue` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `issue_priority_fk_priority` FOREIGN KEY (`priority`) REFERENCES `priority` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `issue_priority_fk_user` FOREIGN KEY (`user`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `issue_status`
--
CREATE TABLE `issue_status` (
  `id` integer NOT NULL auto_increment,
  `issue` integer NOT NULL,
  `status` integer NOT NULL,
  `datetime` datetime NULL,
  `user` integer NULL,
  INDEX `issue_status_idx_issue` (`issue`),
  INDEX `issue_status_idx_status` (`status`),
  INDEX `issue_status_idx_user` (`user`),
  PRIMARY KEY (`id`),
  CONSTRAINT `issue_status_fk_issue` FOREIGN KEY (`issue`) REFERENCES `issue` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `issue_status_fk_status` FOREIGN KEY (`status`) REFERENCES `status` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `issue_status_fk_user` FOREIGN KEY (`user`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `issuetype`
--
CREATE TABLE `issuetype` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `permission`
--
CREATE TABLE `permission` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(45) NULL,
  `description` text NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `priority`
--
CREATE TABLE `priority` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `project`
--
CREATE TABLE `project` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `pw`
--
CREATE TABLE `pw` (
  `id` integer NOT NULL auto_increment,
  `server_id` integer NULL,
  `uad_id` integer NULL,
  `username` varchar(45) NULL,
  `password` varchar(45) NULL,
  `pwencrypt` blob NULL,
  `type` varchar(128) NULL,
  `last_changed` datetime NULL,
  INDEX `pw_idx_server_id` (`server_id`),
  INDEX `pw_idx_uad_id` (`uad_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `pw_fk_server_id` FOREIGN KEY (`server_id`) REFERENCES `server` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `pw_fk_uad_id` FOREIGN KEY (`uad_id`) REFERENCES `uad` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `server`
--
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
--
-- Table: `server_cert`
--
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
--
-- Table: `server_pw`
--
CREATE TABLE `server_pw` (
  `id` integer NOT NULL auto_increment,
  `server_id` integer NULL,
  `pw_id` integer NULL,
  INDEX `server_pw_idx_pw_id` (`pw_id`),
  INDEX `server_pw_idx_server_id` (`server_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `server_pw_fk_pw_id` FOREIGN KEY (`pw_id`) REFERENCES `pw` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `server_pw_fk_server_id` FOREIGN KEY (`server_id`) REFERENCES `server` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `server_servertype`
--
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
--
-- Table: `servertype`
--
CREATE TABLE `servertype` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(45) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `site`
--
CREATE TABLE `site` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  `server_id` integer NULL,
  INDEX `site_idx_server_id` (`server_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `site_fk_server_id` FOREIGN KEY (`server_id`) REFERENCES `server` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `status`
--
CREATE TABLE `status` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `uad`
--
CREATE TABLE `uad` (
  `id` integer NOT NULL auto_increment,
  `name` text NULL,
  `owner` integer NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `user`
--
CREATE TABLE `user` (
  `id` integer NOT NULL auto_increment,
  `username` varchar(128) NOT NULL,
  `firstname` varchar(128) NULL,
  `surname` varchar(128) NULL,
  `email` varchar(128) NULL,
  `deleted` datetime NULL,
  `password` varchar(128) NULL,
  `pwchanged` datetime NULL,
  `pwresetcode` char(32) NULL,
  `lastlogin` datetime NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `user_permission`
--
CREATE TABLE `user_permission` (
  `id` integer NOT NULL auto_increment,
  `user` integer NULL,
  `permission` integer NULL,
  INDEX `user_permission_idx_permission` (`permission`),
  INDEX `user_permission_idx_user` (`user`),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_permission_fk_permission` FOREIGN KEY (`permission`) REFERENCES `permission` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_permission_fk_user` FOREIGN KEY (`user`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `user_project`
--
CREATE TABLE `user_project` (
  `id` integer NOT NULL auto_increment,
  `user` integer NOT NULL,
  `project` integer NOT NULL,
  INDEX `user_project_idx_project` (`project`),
  INDEX `user_project_idx_user` (`user`),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_project_fk_project` FOREIGN KEY (`project`) REFERENCES `project` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_project_fk_user` FOREIGN KEY (`user`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `user_topic`
--
CREATE TABLE `user_topic` (
  `id` integer NOT NULL auto_increment,
  `user` integer NOT NULL,
  `topic` integer NOT NULL,
  INDEX `user_topic_idx_user` (`user`),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_topic_fk_user` FOREIGN KEY (`user`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
SET foreign_key_checks=1;
