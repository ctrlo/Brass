-- Convert schema '/srv/Brass/share/migrations/_source/deploy/28/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/29/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user ADD COLUMN lastfail timestamp;

;
ALTER TABLE user ADD COLUMN failcount integer DEFAULT 0 NOT NULL;

;

COMMIT;

