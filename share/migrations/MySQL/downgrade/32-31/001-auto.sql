-- Convert schema '/srv/Brass/share/migrations/_source/deploy/32/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/31/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calendar DROP FOREIGN KEY calendar_fk_user_id;

;
DROP TABLE calendar;

;

COMMIT;

