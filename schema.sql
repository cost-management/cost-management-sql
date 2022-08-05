create extension if not exists "uuid-ossp" with schema public;

create table gender (
    id uuid default public.uuid_generate_v4() primary key,
    name text unique not null
);

create table currency (
    id uuid default public.uuid_generate_v4() primary key,
    name text unique not null
);

create table folder_type (
    id uuid default public.uuid_generate_v4() primary key,
    name text unique not null
);

create table income_category (
    id uuid default public.uuid_generate_v4() primary key,
    name text unique not null
);

create table customer (
    customer_id uuid default public.uuid_generate_v4() primary key,
    email text unique not null,
    birthday time,
    nick_name text,
    last_login timestamp,
    first_login timestamp,
    gender_id uuid references gender(id)
);

create table customer_folder (
    customer_id uuid not null references customer(customer_id),
    folder_id uuid not null references folder(id),
    constraint customer_budget_id primary key (customer_id, folder_id)
);

create table invite (
    folder_owner_id uuid not null references customer(customer_id),
    folder_id uuid not null references folder(id),
    invited_customer_id uuid not null references customer(customer_id),
    constraint invite_id primary key (folder_owner_id, folder_id, invited_customer_id)
);

create table folder (
    id uuid default public.uuid_generate_v4() primary key,
    owner_id uuid references customer(customer_id) on delete cascade,
    title text,
    type_id uuid references folder_type(id),
    currency_id uuid references currency(id),
    created_at timestamp
);

create table income (
    id uuid default public.uuid_generate_v4() primary key,
    title text,
    folder_id uuid references folder(id) on delete cascade,
    category_id uuid references income_category(id),
    customer_id uuid references customer(customer_id),
    create_at timestamp,
    amount decimal not null
)