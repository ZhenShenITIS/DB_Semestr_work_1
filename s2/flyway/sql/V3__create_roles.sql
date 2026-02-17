CREATE ROLE admin_user WITH LOGIN PASSWORD '${adminPassword}';
CREATE ROLE read_only WITH LOGIN PASSWORD '${readonlyPassword}';
CREATE ROLE app_user WITH LOGIN PASSWORD '${appPassword}';

GRANT ALL PRIVILEGES ON DATABASE autoservice TO admin_user;
GRANT ALL PRIVILEGES ON SCHEMA autoservice_schema TO admin_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA autoservice_schema TO admin_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA autoservice_schema TO admin_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA autoservice_schema
    GRANT ALL ON TABLES TO admin_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA autoservice_schema
    GRANT ALL ON SEQUENCES TO admin_user;


GRANT CONNECT ON DATABASE autoservice TO read_only;
GRANT USAGE ON SCHEMA autoservice_schema TO read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA autoservice_schema TO read_only;
ALTER DEFAULT PRIVILEGES IN SCHEMA autoservice_schema
    GRANT SELECT ON TABLES TO read_only;


GRANT CONNECT ON DATABASE autoservice TO app_user;
GRANT USAGE ON SCHEMA autoservice_schema TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA autoservice_schema TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA autoservice_schema TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA autoservice_schema
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA autoservice_schema
    GRANT USAGE, SELECT ON SEQUENCES TO app_user;