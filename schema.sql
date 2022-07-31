create table gender (
    id uuid primary key,
    name text unique not null
);

create table currency (
    id uuid primary key,
    name text unique not null
);

create table folder_type (
    id uuid primary key,
    name text unique not null
);

create table income_category (
    id uuid primary key,
    name text unique not null
);

create table customer (
    customer_id uuid primary key,
    email text unique not null,
    birthday time,
    nick_name text,
    last_login timestamp,
    first_login timestamp,
    gender_id uuid references gender(id)
);

create table budget (
    id uuid primary key,
    title text not null,
    owner_id uuid references customer(customer_id) on delete cascade,
    created_at timestamp
);

create table customer_budget (
    customer_id uuid not null references budget(id),
    budget_id uuid not null references customer(customer_id),
    constraint customer_budget_id primary key (customer_id, budget_id)
);

create table invite (
    budget_owner_id uuid not null references customer(customer_id),
    budget_id uuid not null references budget(id),
    invited_customer_id uuid not null references customer(customer_id),
    constraint invite_id primary key (budget_owner_id, budget_id, invited_customer_id)
);

create table folder (
    id uuid primary key,
    budget_id uuid not null references budget(id),
    title text,
    type_id uuid references folder_type(id),
    currency_id uuid references currency(id),
    created_at timestamp
);

create table income (
    id uuid primary key,
    title text,
    category_id uuid references income_category(id),
    customer_id uuid references customer(customer_id),
    create_at timestamp,
    amount decimal not null
)