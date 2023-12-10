-- Convert schema '/srv/Brass/share/migrations/_source/deploy/35/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/34/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE cert DROP COLUMN description,
                 DROP COLUMN content_cert,
                 DROP COLUMN content_key,
                 DROP COLUMN content_ca;

;
ALTER TABLE cert_location DROP FOREIGN KEY cert_location_fk_cert_id;

;
DROP TABLE cert_location;

;
ALTER TABLE cert_location_use DROP FOREIGN KEY cert_location_use_fk_cert_location_id,
                              DROP FOREIGN KEY cert_location_use_fk_use_id;

;
DROP TABLE cert_location_use;

;

COMMIT;

