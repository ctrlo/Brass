-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Fri Jan 15 08:57:49 2021
-- 
;
--
-- Table: app
--
CREATE TABLE "app" (
  "id" serial NOT NULL,
  "status_last_run" timestamp,
  PRIMARY KEY ("id")
);

;
--
-- Table: cert
--
CREATE TABLE "cert" (
  "id" serial NOT NULL,
  "content" text,
  "cn" character varying(45),
  "type" character varying(45),
  "expiry" date,
  "usedby" character varying(45),
  "filename" character varying(256),
  "file_user" text,
  "file_group" text,
  PRIMARY KEY ("id")
);

;
--
-- Table: cert_use
--
CREATE TABLE "cert_use" (
  "id" serial NOT NULL,
  "name" character varying(128),
  PRIMARY KEY ("id")
);

;
--
-- Table: comment
--
CREATE TABLE "comment" (
  "id" serial NOT NULL,
  "author" integer NOT NULL,
  "issue" integer NOT NULL,
  "datetime" timestamp,
  "text" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "comment_idx_author" on "comment" ("author");
CREATE INDEX "comment_idx_issue" on "comment" ("issue");

;
--
-- Table: customer
--
CREATE TABLE "customer" (
  "id" serial NOT NULL,
  "name" text,
  "authnames" text,
  "updated" timestamp,
  "updated_by" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "customer_idx_updated_by" on "customer" ("updated_by");

;
--
-- Table: docsend
--
CREATE TABLE "docsend" (
  "id" serial NOT NULL,
  "doc_id" integer,
  "email" text,
  "code" character varying(32),
  "created" timestamp,
  "download_time" timestamp,
  "download_ip_address" text,
  PRIMARY KEY ("id"),
  CONSTRAINT "docsend_ux_code" UNIQUE ("code")
);

;
--
-- Table: domain
--
CREATE TABLE "domain" (
  "id" serial NOT NULL,
  "name" character varying(45),
  PRIMARY KEY ("id")
);

;
--
-- Table: event
--
CREATE TABLE "event" (
  "id" serial NOT NULL,
  "title" character varying(256),
  "description" text,
  "from" timestamp,
  "to" timestamp,
  "editor_id" integer,
  "eventtype_id" integer,
  "customer_id" integer,
  "invoiced" smallint DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "event_idx_customer_id" on "event" ("customer_id");
CREATE INDEX "event_idx_editor_id" on "event" ("editor_id");
CREATE INDEX "event_idx_eventtype_id" on "event" ("eventtype_id");

;
--
-- Table: event_person
--
CREATE TABLE "event_person" (
  "id" serial NOT NULL,
  "event_id" integer,
  "user_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "event_person_idx_event_id" on "event_person" ("event_id");
CREATE INDEX "event_person_idx_user_id" on "event_person" ("user_id");

;
--
-- Table: eventtype
--
CREATE TABLE "eventtype" (
  "id" serial NOT NULL,
  "name" character varying(128),
  PRIMARY KEY ("id")
);

;
--
-- Table: file
--
CREATE TABLE "file" (
  "id" serial NOT NULL,
  "uploaded_by" integer NOT NULL,
  "issue" integer NOT NULL,
  "datetime" timestamp,
  "name" text,
  "mimetype" text,
  "content" bytea,
  PRIMARY KEY ("id")
);
CREATE INDEX "file_idx_issue" on "file" ("issue");
CREATE INDEX "file_idx_uploaded_by" on "file" ("uploaded_by");

;
--
-- Table: issue
--
CREATE TABLE "issue" (
  "id" serial NOT NULL,
  "title" character varying(256),
  "description" text,
  "completion_time" text,
  "type" integer,
  "author" integer,
  "owner" integer,
  "approver" integer,
  "reference" character varying(128),
  "project" integer,
  "security" smallint DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "issue_idx_approver" on "issue" ("approver");
CREATE INDEX "issue_idx_author" on "issue" ("author");
CREATE INDEX "issue_idx_owner" on "issue" ("owner");
CREATE INDEX "issue_idx_project" on "issue" ("project");
CREATE INDEX "issue_idx_type" on "issue" ("type");

;
--
-- Table: issue_priority
--
CREATE TABLE "issue_priority" (
  "id" serial NOT NULL,
  "issue" integer NOT NULL,
  "priority" integer NOT NULL,
  "datetime" timestamp,
  "user" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "issue_priority_idx_issue" on "issue_priority" ("issue");
CREATE INDEX "issue_priority_idx_priority" on "issue_priority" ("priority");
CREATE INDEX "issue_priority_idx_user" on "issue_priority" ("user");

;
--
-- Table: issue_status
--
CREATE TABLE "issue_status" (
  "id" serial NOT NULL,
  "issue" integer NOT NULL,
  "status" integer NOT NULL,
  "datetime" timestamp,
  "user" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "issue_status_idx_issue" on "issue_status" ("issue");
CREATE INDEX "issue_status_idx_status" on "issue_status" ("status");
CREATE INDEX "issue_status_idx_user" on "issue_status" ("user");

;
--
-- Table: issue_tag
--
CREATE TABLE "issue_tag" (
  "id" serial NOT NULL,
  "issue" integer NOT NULL,
  "tag" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "issue_tag_idx_issue" on "issue_tag" ("issue");
CREATE INDEX "issue_tag_idx_tag" on "issue_tag" ("tag");

;
--
-- Table: issuetype
--
CREATE TABLE "issuetype" (
  "id" serial NOT NULL,
  "name" character varying(128),
  PRIMARY KEY ("id")
);

;
--
-- Table: permission
--
CREATE TABLE "permission" (
  "id" serial NOT NULL,
  "name" character varying(45),
  "description" character varying(256),
  PRIMARY KEY ("id")
);

;
--
-- Table: priority
--
CREATE TABLE "priority" (
  "id" serial NOT NULL,
  "name" character varying(128),
  PRIMARY KEY ("id")
);

;
--
-- Table: project
--
CREATE TABLE "project" (
  "id" serial NOT NULL,
  "name" character varying(128),
  PRIMARY KEY ("id")
);

;
--
-- Table: pw
--
CREATE TABLE "pw" (
  "id" serial NOT NULL,
  "server_id" integer,
  "uad_id" integer,
  "username" character varying(45),
  "user_id" integer,
  "password" character varying(45),
  "pwencrypt" bytea,
  "type" character varying(128),
  "last_changed" timestamp,
  "publickey" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "pw_idx_server_id" on "pw" ("server_id");
CREATE INDEX "pw_idx_uad_id" on "pw" ("uad_id");
CREATE INDEX "pw_idx_user_id" on "pw" ("user_id");

;
--
-- Table: server
--
CREATE TABLE "server" (
  "id" serial NOT NULL,
  "name" character varying(128),
  "domain_id" integer,
  "sudo" text,
  "update_datetime" timestamp,
  "update_result" text,
  "restart_required" text,
  "os_version" character varying(128),
  "backup_verify" text,
  "notes" text,
  "is_production" smallint DEFAULT 0 NOT NULL,
  "local_ip" text,
  PRIMARY KEY ("id"),
  CONSTRAINT "name_UNIQUE" UNIQUE ("name")
);
CREATE INDEX "server_idx_domain_id" on "server" ("domain_id");

;
--
-- Table: server_cert
--
CREATE TABLE "server_cert" (
  "id" serial NOT NULL,
  "server_id" integer NOT NULL,
  "cert_id" integer NOT NULL,
  "type" character varying(45),
  "use" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "server_cert_idx_cert_id" on "server_cert" ("cert_id");
CREATE INDEX "server_cert_idx_server_id" on "server_cert" ("server_id");
CREATE INDEX "server_cert_idx_use" on "server_cert" ("use");

;
--
-- Table: server_pw
--
CREATE TABLE "server_pw" (
  "id" serial NOT NULL,
  "server_id" integer,
  "pw_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "server_pw_idx_pw_id" on "server_pw" ("pw_id");
CREATE INDEX "server_pw_idx_server_id" on "server_pw" ("server_id");

;
--
-- Table: server_servertype
--
CREATE TABLE "server_servertype" (
  "id" serial NOT NULL,
  "server_id" integer NOT NULL,
  "servertype_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "server_servertype_idx_server_id" on "server_servertype" ("server_id");
CREATE INDEX "server_servertype_idx_servertype_id" on "server_servertype" ("servertype_id");

;
--
-- Table: servertype
--
CREATE TABLE "servertype" (
  "id" serial NOT NULL,
  "name" character varying(45),
  PRIMARY KEY ("id")
);

;
--
-- Table: site
--
CREATE TABLE "site" (
  "id" serial NOT NULL,
  "name" character varying(128),
  "server_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "site_idx_server_id" on "site" ("server_id");

;
--
-- Table: status
--
CREATE TABLE "status" (
  "id" serial NOT NULL,
  "name" character varying(128),
  PRIMARY KEY ("id")
);

;
--
-- Table: tag
--
CREATE TABLE "tag" (
  "id" serial NOT NULL,
  "name" character varying(128),
  PRIMARY KEY ("id")
);

;
--
-- Table: uad
--
CREATE TABLE "uad" (
  "id" serial NOT NULL,
  "name" character varying(256),
  "owner" integer,
  PRIMARY KEY ("id")
);

;
--
-- Table: user
--
CREATE TABLE "user" (
  "id" serial NOT NULL,
  "username" character varying(128) NOT NULL,
  "firstname" character varying(128),
  "surname" character varying(128),
  "email" character varying(128),
  "deleted" timestamp,
  "password" character varying(128),
  "pwchanged" timestamp,
  "pwresetcode" character(32),
  "lastlogin" timestamp,
  PRIMARY KEY ("id")
);

;
--
-- Table: user_permission
--
CREATE TABLE "user_permission" (
  "id" serial NOT NULL,
  "user" integer,
  "permission" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_permission_idx_permission" on "user_permission" ("permission");
CREATE INDEX "user_permission_idx_user" on "user_permission" ("user");

;
--
-- Table: user_project
--
CREATE TABLE "user_project" (
  "id" serial NOT NULL,
  "user" integer NOT NULL,
  "project" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_project_idx_project" on "user_project" ("project");
CREATE INDEX "user_project_idx_user" on "user_project" ("user");

;
--
-- Table: user_servertype
--
CREATE TABLE "user_servertype" (
  "id" serial NOT NULL,
  "user" integer NOT NULL,
  "servertype" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_servertype_idx_servertype" on "user_servertype" ("servertype");
CREATE INDEX "user_servertype_idx_user" on "user_servertype" ("user");

;
--
-- Table: user_topic
--
CREATE TABLE "user_topic" (
  "id" serial NOT NULL,
  "user" integer NOT NULL,
  "topic" integer NOT NULL,
  "permission" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_topic_idx_permission" on "user_topic" ("permission");
CREATE INDEX "user_topic_idx_user" on "user_topic" ("user");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "comment" ADD CONSTRAINT "comment_fk_author" FOREIGN KEY ("author")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "comment" ADD CONSTRAINT "comment_fk_issue" FOREIGN KEY ("issue")
  REFERENCES "issue" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "customer" ADD CONSTRAINT "customer_fk_updated_by" FOREIGN KEY ("updated_by")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "event" ADD CONSTRAINT "event_fk_customer_id" FOREIGN KEY ("customer_id")
  REFERENCES "customer" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "event" ADD CONSTRAINT "event_fk_editor_id" FOREIGN KEY ("editor_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "event" ADD CONSTRAINT "event_fk_eventtype_id" FOREIGN KEY ("eventtype_id")
  REFERENCES "eventtype" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "event_person" ADD CONSTRAINT "event_person_fk_event_id" FOREIGN KEY ("event_id")
  REFERENCES "event" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "event_person" ADD CONSTRAINT "event_person_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "file" ADD CONSTRAINT "file_fk_issue" FOREIGN KEY ("issue")
  REFERENCES "issue" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "file" ADD CONSTRAINT "file_fk_uploaded_by" FOREIGN KEY ("uploaded_by")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "issue" ADD CONSTRAINT "issue_fk_approver" FOREIGN KEY ("approver")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "issue" ADD CONSTRAINT "issue_fk_author" FOREIGN KEY ("author")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "issue" ADD CONSTRAINT "issue_fk_owner" FOREIGN KEY ("owner")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "issue" ADD CONSTRAINT "issue_fk_project" FOREIGN KEY ("project")
  REFERENCES "project" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "issue" ADD CONSTRAINT "issue_fk_type" FOREIGN KEY ("type")
  REFERENCES "issuetype" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "issue_priority" ADD CONSTRAINT "issue_priority_fk_issue" FOREIGN KEY ("issue")
  REFERENCES "issue" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "issue_priority" ADD CONSTRAINT "issue_priority_fk_priority" FOREIGN KEY ("priority")
  REFERENCES "priority" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "issue_priority" ADD CONSTRAINT "issue_priority_fk_user" FOREIGN KEY ("user")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "issue_status" ADD CONSTRAINT "issue_status_fk_issue" FOREIGN KEY ("issue")
  REFERENCES "issue" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "issue_status" ADD CONSTRAINT "issue_status_fk_status" FOREIGN KEY ("status")
  REFERENCES "status" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "issue_status" ADD CONSTRAINT "issue_status_fk_user" FOREIGN KEY ("user")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "issue_tag" ADD CONSTRAINT "issue_tag_fk_issue" FOREIGN KEY ("issue")
  REFERENCES "issue" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "issue_tag" ADD CONSTRAINT "issue_tag_fk_tag" FOREIGN KEY ("tag")
  REFERENCES "tag" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "pw" ADD CONSTRAINT "pw_fk_server_id" FOREIGN KEY ("server_id")
  REFERENCES "server" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "pw" ADD CONSTRAINT "pw_fk_uad_id" FOREIGN KEY ("uad_id")
  REFERENCES "uad" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "pw" ADD CONSTRAINT "pw_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "server" ADD CONSTRAINT "server_fk_domain_id" FOREIGN KEY ("domain_id")
  REFERENCES "domain" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "server_cert" ADD CONSTRAINT "server_cert_fk_cert_id" FOREIGN KEY ("cert_id")
  REFERENCES "cert" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "server_cert" ADD CONSTRAINT "server_cert_fk_server_id" FOREIGN KEY ("server_id")
  REFERENCES "server" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "server_cert" ADD CONSTRAINT "server_cert_fk_use" FOREIGN KEY ("use")
  REFERENCES "cert_use" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "server_pw" ADD CONSTRAINT "server_pw_fk_pw_id" FOREIGN KEY ("pw_id")
  REFERENCES "pw" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "server_pw" ADD CONSTRAINT "server_pw_fk_server_id" FOREIGN KEY ("server_id")
  REFERENCES "server" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "server_servertype" ADD CONSTRAINT "server_servertype_fk_server_id" FOREIGN KEY ("server_id")
  REFERENCES "server" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "server_servertype" ADD CONSTRAINT "server_servertype_fk_servertype_id" FOREIGN KEY ("servertype_id")
  REFERENCES "servertype" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "site" ADD CONSTRAINT "site_fk_server_id" FOREIGN KEY ("server_id")
  REFERENCES "server" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_permission" ADD CONSTRAINT "user_permission_fk_permission" FOREIGN KEY ("permission")
  REFERENCES "permission" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_permission" ADD CONSTRAINT "user_permission_fk_user" FOREIGN KEY ("user")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_project" ADD CONSTRAINT "user_project_fk_project" FOREIGN KEY ("project")
  REFERENCES "project" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_project" ADD CONSTRAINT "user_project_fk_user" FOREIGN KEY ("user")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_servertype" ADD CONSTRAINT "user_servertype_fk_servertype" FOREIGN KEY ("servertype")
  REFERENCES "servertype" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_servertype" ADD CONSTRAINT "user_servertype_fk_user" FOREIGN KEY ("user")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_topic" ADD CONSTRAINT "user_topic_fk_permission" FOREIGN KEY ("permission")
  REFERENCES "permission" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_topic" ADD CONSTRAINT "user_topic_fk_user" FOREIGN KEY ("user")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
