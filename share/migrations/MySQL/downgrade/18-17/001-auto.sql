-- Convert schema '/srv/Brass/share/migrations/_source/deploy/18/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/17/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE event_person DROP FOREIGN KEY event_person_fk_event_id,
                         DROP FOREIGN KEY event_person_fk_user_id;

;
DROP TABLE event_person;

;
ALTER TABLE event DROP FOREIGN KEY event_fk_customer_id,
                  DROP FOREIGN KEY event_fk_editor_id,
                  DROP FOREIGN KEY event_fk_eventtype_id;

;
DROP TABLE event;

;
DROP TABLE eventtype;

;

COMMIT;

