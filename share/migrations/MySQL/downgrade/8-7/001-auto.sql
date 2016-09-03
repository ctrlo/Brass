-- Convert schema '/srv/Brass/share/migrations/_source/deploy/8/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE issue DROP FOREIGN KEY issue_fk_type;

;
ALTER TABLE issue ADD CONSTRAINT issue_fk_type FOREIGN KEY (type) REFERENCES type (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE issuetype;

;
ALTER TABLE type ENGINE=InnoDB;

;

COMMIT;

