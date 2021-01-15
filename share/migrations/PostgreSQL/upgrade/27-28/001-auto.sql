-- Convert schema '/srv/Brass/share/migrations/_source/deploy/27/001-auto.yml' to '/srv/Brass/share/migrations/_source/deploy/28/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "app" (
  "id" serial NOT NULL,
  "status_last_run" timestamp,
  PRIMARY KEY ("id")
);

;

COMMIT;

