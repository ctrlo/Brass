-- Convert schema '/srv/Brass/share/migrations/_source/deploy/10/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE server_cert DROP FOREIGN KEY server_cert_fk_cert_id,
                        DROP FOREIGN KEY server_cert_fk_server_id,
                        DROP FOREIGN KEY server_cert_fk_use;

;
DROP TABLE server_cert;

;
DROP TABLE cert_use;

;
ALTER TABLE pw DROP FOREIGN KEY pw_fk_server_id,
               DROP FOREIGN KEY pw_fk_uad_id;

;
DROP TABLE pw;

;
ALTER TABLE server_servertype DROP FOREIGN KEY server_servertype_fk_server_id,
                              DROP FOREIGN KEY server_servertype_fk_servertype_id;

;
DROP TABLE server_servertype;

;
DROP TABLE servertype;

;
ALTER TABLE site DROP FOREIGN KEY site_fk_server_id;

;
DROP TABLE site;

;
ALTER TABLE server DROP FOREIGN KEY server_fk_domain_id;

;
DROP TABLE server;

;
DROP TABLE domain;

;
DROP TABLE uad;

;
DROP TABLE cert;

;

COMMIT;

