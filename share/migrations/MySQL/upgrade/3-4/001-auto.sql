-- Convert schema '/home/abeverley/git/Brass/share/migrations/_source/deploy/3/001-auto.yml' to '/home/abeverley/git/Brass/share/migrations/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
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

;
SET foreign_key_checks=1;

;
ALTER TABLE issue DROP FOREIGN KEY issue_fk_priority,
                  DROP INDEX issue_idx_priority,
                  DROP COLUMN priority,
                  ADD COLUMN approver integer NULL,
                  ADD COLUMN security smallint NOT NULL DEFAULT 0,
                  ADD INDEX issue_idx_approver (approver),
                  ADD CONSTRAINT issue_fk_approver FOREIGN KEY (approver) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE issue_status ADD COLUMN user integer NULL,
                         ADD INDEX issue_status_idx_user (user),
                         ADD CONSTRAINT issue_status_fk_user FOREIGN KEY (user) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

