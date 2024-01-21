-- Convert schema '/srv/Brass/share/migrations/_source/deploy/39/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/40/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE issue ADD COLUMN target_date datetime NULL,
                  ADD COLUMN resources_required text NULL,
                  ADD COLUMN success_description text NULL;

;

COMMIT;

