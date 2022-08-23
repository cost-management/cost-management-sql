--DROP SCHEMA public CASCADE;
--CREATE SCHEMA public;

create extension if not exists "uuid-ossp" with schema public;

create type currency as enum ('UAH', 'USD');
create type folder_type as enum ('CARD', 'CASH');
create type income_category as enum ('FOOD', 'CAFE');
create type gender as enum ('UNDEFINED', 'MALE', 'FEMALE');
create type customer_folder_role as enum ('OWNER', 'ADMIN', 'USER');
create type folder_skin as enum ('BLUE', 'GREEN', 'RED');

create table customer
(
    id         uuid primary key not null,
    email      text unique      not null,
    birthday   time,
    nick_name  text,
    age        smallint,
    gender     gender           not null default 'UNDEFINED',
    created_at timestamptz               default now()
);

create table folder
(
    id          uuid                 default public.uuid_generate_v4() primary key,
    title       text        not null,
    folder_type folder_type not null default 'CARD',
    units       bigint      not null default 0,
    nanos       smallint    not null default 0,
    currency    currency    not null default 'UAH',
    skin        folder_skin not null default 'BLUE',
    created_at  timestamptz          default now()
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
    created_at          timestamptz                   default now(),
    constraint invite_id primary key (folder_id, invited_customer_id)
);

create table income
(
    id              uuid                     default public.uuid_generate_v4() primary key,
    title           text,
    folder_id       uuid references folder on delete cascade,
    income_category income_category not null default 'FOOD',
    customer_id     uuid            not null references customer on delete cascade,
    created_at      timestamptz              default now(),
    units           bigint          not null default 0,
    nanos           smallint        not null default 0,
    timezone        smallint        not null default 0
);

create function add_amount_to_folder() returns trigger as
$trigger_bound$
declare
    rest_units         smallint := ((select nanos
                                     from folder
                                     where folder.id = NEW.folder_id) + new.nanos) / 100;
    declare rest_nanos smallint := ((select nanos
                                     from folder
                                     where folder.id = NEW.folder_id) + new.nanos) % 100;
begin
    if rest_units = 0 then
        update folder set units = NEW.units + folder.units where folder.id = NEW.folder_id;
        update folder set nanos = NEW.nanos + folder.nanos where folder.id = NEW.folder_id;
        return NEW;
    end if;

    if rest_units > 0 then
        update folder set units = NEW.units + folder.units + rest_units where folder.id = NEW.folder_id;
        update folder set nanos = rest_nanos where folder.id = NEW.folder_id;
        return NEW;
    end if;

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
    rest_nanos smallint := ((select nanos
                             from folder
                             where folder.id = OLD.folder_id) - OLD.nanos) % 100;
begin
    if rest_nanos < 0 then
        update folder set units = folder.units - OLD.units - 1 where folder.id = OLD.folder_id;
        update folder set nanos = 100 + rest_nanos where folder.id = OLD.folder_id;
        return OLD;
    end if;

    update folder set units = folder.units - OLD.units where folder.id = OLD.folder_id;
    update folder set nanos = folder.nanos - OLD.nanos where folder.id = OLD.folder_id;

    return OLD;
end;
$trigger_bound$
    language plpgsql;

create trigger folder_amount_sub

    after delete

    on income

    for each row

execute procedure subtract_amount_to_folder();