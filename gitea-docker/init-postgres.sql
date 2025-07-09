-- =============================================================================
-- Script de inicialização do PostgreSQL para DevOps Stack
-- Cria usuários e databases para Gitea, SonarQube e Drone CI
-- =============================================================================

-- Garantir que postgres_root tenha todos os privilégios
ALTER USER postgres_root WITH SUPERUSER CREATEDB CREATEROLE REPLICATION BYPASSRLS;

-- =============================================================================
-- CRIAR USUÁRIOS ESPECÍFICOS PARA AS APLICAÇÕES
-- =============================================================================
-- Usuário para SonarQube
CREATE USER user_sonarqube WITH PASSWORD '12345678sonarqube' SUPERUSER CREATEDB CREATEROLE;

-- Usuário para Gitea
CREATE USER user_gitea WITH PASSWORD '12345678gitea' SUPERUSER CREATEDB CREATEROLE;

-- Usuário para Drone CI
CREATE USER user_drone WITH PASSWORD '12345678drone' SUPERUSER CREATEDB CREATEROLE;

-- =============================================================================
-- CRIAR DATABASES
-- =============================================================================
-- Database para SonarQube
CREATE DATABASE sonarqube WITH 
    ENCODING 'UTF8' 
    LC_COLLATE='C' 
    LC_CTYPE='C' 
    TEMPLATE template0
    OWNER user_sonarqube;

-- Database para Gitea
CREATE DATABASE gitea WITH 
    ENCODING 'UTF8' 
    LC_COLLATE='C' 
    LC_CTYPE='C' 
    TEMPLATE template0
    OWNER user_gitea;

-- Database para Drone CI
CREATE DATABASE drone WITH 
    ENCODING 'UTF8' 
    LC_COLLATE='C' 
    LC_CTYPE='C' 
    TEMPLATE template0
    OWNER user_drone;

-- =============================================================================
-- PERMISSÕES PARA postgres_root (ADMIN GLOBAL)
-- =============================================================================

-- Conceder todas as permissões para postgres_root em todos os databases
GRANT ALL PRIVILEGES ON DATABASE postgres TO postgres_root;
GRANT ALL PRIVILEGES ON DATABASE sonarqube TO postgres_root;
GRANT ALL PRIVILEGES ON DATABASE gitea TO postgres_root;
GRANT ALL PRIVILEGES ON DATABASE drone TO postgres_root;

-- Conceder privilégios nos schemas para postgres_root
\c sonarqube;
GRANT ALL ON SCHEMA public TO postgres_root;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres_root;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres_root;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO postgres_root;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres_root;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres_root;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres_root;

-- Permissões para user_sonarqube
GRANT ALL PRIVILEGES ON DATABASE sonarqube TO user_sonarqube;
GRANT ALL ON SCHEMA public TO user_sonarqube;
GRANT ALL ON SCHEMA public TO public;
GRANT USAGE ON SCHEMA public TO user_sonarqube;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO user_sonarqube;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO user_sonarqube;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO user_sonarqube;


-- =============================================================================
-- CONFIGURAÇÕES ESPECÍFICAS PARA GITEA
-- =============================================================================
\c gitea;
-- Permissões para postgres_root
GRANT ALL ON SCHEMA public TO postgres_root;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres_root;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres_root;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO postgres_root;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres_root;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres_root;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres_root;

-- Permissões para user_gitea
GRANT ALL PRIVILEGES ON DATABASE gitea TO user_gitea;
GRANT ALL ON SCHEMA public TO user_gitea;
GRANT ALL ON SCHEMA public TO public;
GRANT USAGE ON SCHEMA public TO user_gitea;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO user_gitea;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO user_gitea;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO user_gitea;

-- =============================================================================
-- CONFIGURAÇÕES ESPECÍFICAS PARA DRONE
-- =============================================================================
\c drone;

-- Permissões para postgres_root
GRANT ALL ON SCHEMA public TO postgres_root;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres_root;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres_root;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO postgres_root;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres_root;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres_root;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres_root;

-- Permissões para user_drone
GRANT ALL PRIVILEGES ON DATABASE drone TO user_drone;
GRANT ALL ON SCHEMA public TO user_drone;
GRANT USAGE ON SCHEMA public TO user_drone;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO user_drone;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO user_drone;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO user_drone;


-- =============================================================================
-- CONFIGURAÇÕES FINAIS DO BANCO PRINCIPAL
-- =============================================================================
\c postgres;

-- Garantir que postgres_root tenha acesso total ao schema public do banco principal
GRANT ALL ON SCHEMA public TO postgres_root;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres_root;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres_root;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO postgres_root;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres_root;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres_root;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres_root;