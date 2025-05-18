-- Convert schema '/srv/Brass/bin/../share/migrations/_source/deploy/47/001-auto.yml' to '/srv/Brass/bin/../share/migrations/_source/deploy/48/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE config ADD COLUMN monitoring_hosts text NULL;

;
ALTER TABLE servertype ADD COLUMN monitoring_hosts text NULL;

;

COMMIT;

