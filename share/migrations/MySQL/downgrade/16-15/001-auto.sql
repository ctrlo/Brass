-- Convert schema '/srv/Brass/share/migrations/_source/deploy/16/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/15/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE customer DROP FOREIGN KEY customer_fk_updated_by;

;
DROP TABLE customer;

;

COMMIT;

