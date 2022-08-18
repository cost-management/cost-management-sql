--DROP SCHEMA public CASCADE;
--CREATE SCHEMA public;

create extension if not exists "uuid-ossp" with schema public;

create type currency as enum ('UAH', 'USD');
create type folder_type as enum ('CARD', 'CASH');
create type income_category as enum ('FOOD', 'CAFE');
create type gender as enum ('UNDEFINED', 'MALE', 'FEMALE');
create type invited_customer_role as enum ('ADMIN', 'USER');

create table customer (
    id uuid not null,
    email text unique not null,
    birthday time,
    nick_name text,
    age smallint,
    gender gender default 'UNDEFINED',
    created_at timestamptz
);

create table folder (
    id uuid default public.uuid_generate_v4() primary key,
    owner_id uuid not null,
    title text,
    folder_type folder_type,
    currency currency,
    created_at timestamptz
);

create table customer_folder (
    customer_id uuid not null references customer,
    folder_id uuid not null references folder,
    constraint customer_budget_id primary key (customer_id, folder_id)
);

create table invite (
    folder_owner_id uuid not null,
    folder_id uuid not null references folder,
    invited_customer_id uuid not null,
    created_at timestamptz,
    constraint invite_id primary key (folder_owner_id, folder_id, invited_customer_id)
);

create table income (
    id uuid default public.uuid_generate_v4() primary key,
    title text,
    folder_id uuid references folder on delete cascade,
    income_category income_category,
    customer_id uuid not null references customer,
    created_at timestamptz,
    amount decimal not null,
    timezone smallint
)