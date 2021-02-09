-- Convert schema '/srv/Brass/share/migrations/_source/deploy/28/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/29/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user ADD COLUMN lastfail datetime NULL,
                 ADD COLUMN failcount integer NOT NULL DEFAULT 0;

;

COMMIT;

