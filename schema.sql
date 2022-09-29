--DROP SCHEMA public CASCADE;
--CREATE SCHEMA public;

create extension if not exists "uuid-ossp" with schema public;

create type currency as enum ('UAH', 'USD');
create type folder_type as enum ('CARD', 'CASH');
create type gender as enum ('UNDEFINED', 'MALE', 'FEMALE');
create type customer_folder_role as enum ('OWNER', 'ADMIN', 'USER');
create type folder_skin as enum ('SKIN1', 'SKIN2', 'SKIN3', 'SKIN4', 'SKIN5', 'SKIN6');

create table customer
(
    id         uuid primary key not null,
    email      text unique      not null,
    birthday   time,
    nick_name  text,
    age        smallint,
    gender     gender           not null default 'UNDEFINED',
    created_at timestamptz      not null default now(),
    token      text             not null
);

create table folder
(
    id          uuid           not null default public.uuid_generate_v4() primary key,
    title       text           not null,
    folder_type folder_type    not null default 'CARD',
    amount      numeric(12, 2) not null default 0,
    currency    currency       not null default 'UAH',
    skin        folder_skin    not null default 'SKIN1',
    color       text           not null default '#3D424A',
    created_at  timestamptz    not null default now()
);

create table customer_folder
(
    customer_id   uuid                 not null references customer on delete cascade,
    folder_id     uuid                 not null references folder on delete cascade,
    customer_role customer_folder_role not null default 'OWNER',
    constraint customer_budget_id primary key (customer_id, folder_id)
);

create table invite
(
    folder_id           uuid                 not null references folder on delete cascade,
    invited_customer_id uuid                 not null references customer on delete cascade,
    customer_role       customer_folder_role not null default 'USER',
    created_at          timestamptz          not null default now(),
    constraint invite_id primary key (folder_id, invited_customer_id)
);

create table income
(
    id              uuid           not null default public.uuid_generate_v4() primary key,
    title           text,
    folder_id       uuid           not null references folder on delete cascade,
    income_category text           not null,
    customer_id     uuid           not null references customer on delete cascade,
    created_at      timestamptz    not null default now(),
    amount          numeric(12, 2) not null default 0,
    timezone        smallint       not null default 0
);

create function add_amount_to_folder() returns trigger as
$trigger_bound$
declare
begin
    update folder set amount = folder.amount + NEW.amount where folder.id = NEW.folder_id;
    return NEW;
end;
$trigger_bound$
    language plpgsql;

create trigger folder_amount_add

    after insert

    on income

    for each row

execute procedure add_amount_to_folder();

create function subtract_amount_to_folder() returns trigger as
$trigger_bound$
declare
begin
    update folder set amount = folder.amount - OLD.amount where folder.id = OLD.folder_id;
    return OLD;
end;
$trigger_bound$
    language plpgsql;

create trigger folder_amount_sub

    after delete

    on income

    for each row

execute procedure subtract_amount_to_folder();