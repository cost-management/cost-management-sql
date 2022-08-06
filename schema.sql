--DROP SCHEMA public CASCADE;
--CREATE SCHEMA public;

create extension if not exists "uuid-ossp" with schema public;

create type currency as enum ('UAN', 'USD');
create type folder_type as enum ('CARD', 'CASH');
create type income_category as enum ('FOOD', 'CAFE');

create table folder (
    id uuid default public.uuid_generate_v4() primary key,
    owner_id uuid not null,
    title text,
    folder_type folder_type,
    currency_id currency,
    created_at timestamp
);

create table customer_folder (
    customer_id uuid not null,
    folder_id uuid not null references folder(id),
    constraint customer_budget_id primary key (customer_id, folder_id)
);

create table invite (
    folder_owner_id uuid not null,
    folder_id uuid not null references folder(id),
    invited_customer_id uuid not null,
    constraint invite_id primary key (folder_owner_id, folder_id, invited_customer_id)
);

create table income (
    id uuid default public.uuid_generate_v4() primary key,
    title text,
    folder_id uuid references folder(id) on delete cascade,
    category_id income_category,
    customer_id uuid not null,
    create_at timestamp,
    amount decimal not null
)