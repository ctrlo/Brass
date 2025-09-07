-- Convert schema '/home/abeverley/git/Brass/bin/../share/migrations/_source/deploy/49/001-auto.yml' to '/home/abeverley/git/Brass/bin/../share/migrations/_source/deploy/50/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user ADD COLUMN mfa_type char(3) NULL,
                 ADD COLUMN mobile text NULL,
                 ADD COLUMN mobile_verified smallint NOT NULL DEFAULT 0,
                 ADD COLUMN mfa_secret text NULL,
                 ADD COLUMN mfa_sms_token text NULL,
                 ADD COLUMN mfa_sms_created datetime NULL,
                 ADD COLUMN mfa_token_previous text NULL,
                 ADD COLUMN mfa_token_previous_used datetime NULL,
                 ADD COLUMN mfa_token_previous_key text NULL,
                 ADD COLUMN mfa_lastfail datetime NULL,
                 ADD COLUMN mfa_failcount integer NOT NULL DEFAULT 0;

;

COMMIT;

