-- Convert schema '/home/abeverley/git/Brass/bin/../share/migrations/_source/deploy/50/001-auto.yml' to '/home/abeverley/git/Brass/bin/../share/migrations/_source/deploy/49/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user DROP COLUMN mfa_type,
                 DROP COLUMN mobile,
                 DROP COLUMN mobile_verified,
                 DROP COLUMN mfa_secret,
                 DROP COLUMN mfa_sms_token,
                 DROP COLUMN mfa_sms_created,
                 DROP COLUMN mfa_token_previous,
                 DROP COLUMN mfa_token_previous_used,
                 DROP COLUMN mfa_token_previous_key,
                 DROP COLUMN mfa_lastfail,
                 DROP COLUMN mfa_failcount;

;

COMMIT;

