-- Convert schema '/srv/Brass/share/migrations/_source/deploy/44/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/43/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE config DROP COLUMN wazuh_manager;

;

COMMIT;

