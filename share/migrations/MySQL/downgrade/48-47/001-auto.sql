-- Convert schema '/srv/Brass/bin/../share/migrations/_source/deploy/48/001-auto.yml' to '/srv/Brass/bin/../share/migrations/_source/deploy/47/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE config DROP COLUMN monitoring_hosts;

;
ALTER TABLE servertype DROP COLUMN monitoring_hosts;

;

COMMIT;

