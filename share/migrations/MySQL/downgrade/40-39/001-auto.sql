-- Convert schema '/srv/Brass/share/migrations/_source/deploy/40/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/39/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE issue DROP COLUMN target_date,
                  DROP COLUMN resources_required,
                  DROP COLUMN success_description;

;

COMMIT;

