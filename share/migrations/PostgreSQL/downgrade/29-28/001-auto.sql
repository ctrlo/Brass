-- Convert schema '/srv/Brass/share/migrations/_source/deploy/29/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/28/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user DROP COLUMN lastfail;

;
ALTER TABLE user DROP COLUMN failcount;

;

COMMIT;

