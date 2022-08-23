--DROP SCHEMA public CASCADE;
--CREATE SCHEMA public;

create extension if not exists "uuid-ossp" with schema public;

create type currency as enum ('UAH', 'USD');
create type folder_type as enum ('CARD', 'CASH');
create type income_category as enum ('FOOD', 'CAFE');
create type gender as enum ('UNDEFINED', 'MALE', 'FEMALE');
create type customer_folder_role as enum ('OWNER', 'ADMIN', 'USER');
create type folder_skin as enum ('BLUE', 'GREEN', 'RED');

create table customer (
    id uuid primary key not null,
    email text unique not null,
    birthday time,
    nick_name text,
    age smallint,
    gender gender not null default 'UNDEFINED',
    created_at timestamptz default now()
);

create table folder (
    id uuid default public.uuid_generate_v4() primary key,
    title text not null,
    folder_type folder_type not null default 'CARD',
    units bigint not null default 0,
    nanos smallint not null default 0,
    currency currency not null default 'UAH',
    skin folder_skin not null default 'BLUE',
    created_at timestamptz default now()
);

create table customer_folder (
    customer_id uuid not null references customer on delete cascade,
    folder_id uuid not null references folder on delete cascade,
    customer_role customer_folder_role not null default 'OWNER',
    constraint customer_budget_id primary key (customer_id, folder_id)
);

create table invite (
    folder_id uuid not null references folder on delete cascade,
    invited_customer_id uuid not null references customer on delete cascade,
    customer_role customer_folder_role not null default 'USER',
    created_at timestamptz default now(),
    constraint invite_id primary key (folder_id, invited_customer_id)
);

create table income (
    id uuid default public.uuid_generate_v4() primary key,
    title text,
    folder_id uuid references folder on delete cascade,
    income_category income_category not null,
    customer_id uuid not null references customer on delete cascade,
    created_at timestamptz default now(),
    units bigint not null default 0,
    nanos smallint not null default 0,
    timezone smallint not null default 0
);

CREATE FUNCTION update_amount() RETURNS trigger AS $trigger_bound$
BEGIN
    UPDATE folder SET units = NEW.units + folder.units;
    update folder set nanos = NEW.nanos + folder.nanos;

    RETURN NEW;
END;
$trigger_bound$
LANGUAGE plpgsql;

CREATE TRIGGER folder_amount_update

  AFTER INSERT

  ON income

  FOR EACH ROW

  execute procedure update_amount();