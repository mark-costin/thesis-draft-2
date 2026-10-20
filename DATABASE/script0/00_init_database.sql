-- Database Initialization Script
-- Name: med_db
-- Description: Creates the dedicated PostgreSQL database and clinical schema for CDSS.

CREATE DATABASE med_db
    WITH 
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Connect to med_db before running remaining table scripts
\c med_db

-- Optional: Create custom schema if not using default public schema
-- CREATE SCHEMA IF NOT EXISTS clinical;
-- SET search_path TO clinical, public;
