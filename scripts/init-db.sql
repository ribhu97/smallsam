-- Initialize Small Sam Database

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create database for testing
CREATE DATABASE smallsam_test_db;

-- Create application user with limited privileges
CREATE USER smallsam_app WITH PASSWORD 'app_password';
GRANT CONNECT ON DATABASE smallsam_db TO smallsam_app;
GRANT CONNECT ON DATABASE smallsam_test_db TO smallsam_app;
GRANT CREATE ON SCHEMA public TO smallsam_app;