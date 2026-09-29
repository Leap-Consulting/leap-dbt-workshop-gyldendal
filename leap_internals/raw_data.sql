-- =====================================================================
-- Publisher Example · raw data generation
--
-- Creates and loads the raw tables with synthetic, deterministic data:
--   SHOP.IMPRINTS, TITLES, CUSTOMERS, ORDERS, ORDER_LINES, REVIEWS
--   PAYMENTS.TRX_EXPORT_V2
--
-- All dates are relative to the day the script runs. The newest orders are
-- from 2 days ago, and the last nightly load ("ADF") ran yesterday at 02:00
-- UTC, i.e. last night's load failed. Source freshness therefore fails on the
-- morning of the workshop (planted issue 3) until leap_internals/03_daily_batch.sql runs.
-- =====================================================================

use role TODO; -- TODO: GYLDENDAL_LOADER?
use warehouse TODO; -- TODO: GYLDENDAL_LOADING?
use database RAW; -- TODO

create schema if not exists shop;
create schema if not exists payments;

-- ---------------------------------------------------------------------
-- IMPRINTS: the publisher's 5 imprints (full reload every night)
-- ---------------------------------------------------------------------
create or replace table shop.imprints as
select
    cast(imprint_id as integer) as imprint_id,
    cast(imprint_name as varchar) as imprint_name,
    cast(genre as varchar) as genre,
    cast(founded_date as date) as founded_date,
    dateadd(minute, 120, cast(dateadd(day, -1, cast(sysdate() as date)) as timestamp_ntz)) as _loaded_at
from (values
    (1, 'Fyrtårn', 'fiction', '1987-03-01'),
    (2, 'Mørkeland', 'crime', '2004-09-01'),
    (3, 'Mælkebøtten', 'children', '1995-05-15'),
    (4, 'Kompas', 'non-fiction', '2010-01-01'),
    (5, 'Lærdom', 'education', '2016-08-01')
) as t(imprint_id, imprint_name, genre, founded_date);

-- ---------------------------------------------------------------------
-- TITLES: 40 titles, 4 of them out of print (full reload every night)
-- One row per edition: each format of a book (hardback, paperback, ebook,
-- audiobook) has its own ISBN. The ISBNs have hyphens here, but not in
-- ORDER_LINES. Prices are in øre (1 DKK = 100 øre).
-- ---------------------------------------------------------------------
create or replace table shop.titles as
select
    cast(isbn as varchar) as isbn,
    cast(title as varchar) as title,
    cast(author as varchar) as author,
    cast(imprint_id as integer) as imprint_id,
    cast(format as varchar) as format,
    cast(price_ore as integer) as price_ore,
    cast(in_print_flag as varchar) as in_print_flag,
    dateadd(minute, 480, cast(dateadd(day, -(200 + cast(abs(hash(cast(isbn as varchar) || 'updated')) % 400 as integer)), dateadd(day, -2, cast(sysdate() as date))) as timestamp_ntz)) as updated_ts,
    dateadd(minute, 120, cast(dateadd(day, -1, cast(sysdate() as date)) as timestamp_ntz)) as _loaded_at
from (values
    ('978-87-7286-101-2', 'Havet mellem os', 'Astrid Kjærgaard', 1, 'hardback', 29995, 'Y'),
    ('978-87-7286-102-9', 'Havet mellem os', 'Astrid Kjærgaard', 1, 'paperback', 14995, 'Y'),
    ('978-87-7286-103-6', 'Havet mellem os', 'Astrid Kjærgaard', 1, 'audiobook', 19995, 'Y'),
    ('978-87-7286-104-3', 'Sommeren der forsvandt', 'Jonas Brix', 1, 'hardback', 27995, 'Y'),
    ('978-87-7286-105-0', 'Sommeren der forsvandt', 'Jonas Brix', 1, 'ebook', 14995, 'Y'),
    ('978-87-7286-106-7', 'De sidste breve', 'Ingrid Bech', 1, 'paperback', 12995, 'Y'),
    ('978-87-7286-107-4', 'Byen der sov', 'Mikkel Thorsen', 1, 'hardback', 24995, 'Y'),
    ('978-87-7286-108-1', 'Glemte stemmer', 'Lærke Holm', 1, 'paperback', 9995, 'N'),
    ('978-87-7286-201-9', 'Den tavse fjord', 'Bo Kragh', 2, 'hardback', 29995, 'Y'),
    ('978-87-7286-202-6', 'Den tavse fjord', 'Bo Kragh', 2, 'paperback', 14995, 'Y'),
    ('978-87-7286-203-3', 'Den tavse fjord', 'Bo Kragh', 2, 'ebook', 12995, 'Y'),
    ('978-87-7286-204-0', 'Spor i sneen', 'Signe Lund Mathiesen', 2, 'hardback', 27995, 'Y'),
    ('978-87-7286-205-7', 'Spor i sneen', 'Signe Lund Mathiesen', 2, 'audiobook', 19995, 'Y'),
    ('978-87-7286-206-4', 'Mørkt vand', 'Bo Kragh', 2, 'paperback', 12995, 'Y'),
    ('978-87-7286-207-1', 'Kold sag', 'Freja Dalsgaard', 2, 'ebook', 9995, 'Y'),
    ('978-87-7286-208-8', 'Sidste tog fra Aarhus', 'Anders Vinther', 2, 'paperback', 9995, 'N'),
    ('978-87-7286-301-6', 'Lille Pindsvin kan ikke sove', 'Karen Holst', 3, 'hardback', 17995, 'Y'),
    ('978-87-7286-302-3', 'Lille Pindsvin kan ikke sove', 'Karen Holst', 3, 'audiobook', 9995, 'Y'),
    ('978-87-7286-303-0', 'Dragen i kælderen', 'Thomas Engelund', 3, 'hardback', 19995, 'Y'),
    ('978-87-7286-304-7', 'Dragen i kælderen', 'Thomas Engelund', 3, 'paperback', 9995, 'Y'),
    ('978-87-7286-305-4', 'Hvem har taget månen?', 'Ida Friis', 3, 'hardback', 14995, 'Y'),
    ('978-87-7286-306-1', 'Superhelte i skolegården', 'Mads Winther', 3, 'paperback', 12995, 'Y'),
    ('978-87-7286-307-8', 'Rumrejsen', 'Mads Winther', 3, 'ebook', 7995, 'Y'),
    ('978-87-7286-308-5', 'ABC med Mælkebøtten', 'Ida Friis', 3, 'hardback', 12995, 'Y'),
    ('978-87-7286-401-3', 'Danmarks glemte øer', 'Henrik Bruun', 4, 'hardback', 34995, 'Y'),
    ('978-87-7286-402-0', 'Danmarks glemte øer', 'Henrik Bruun', 4, 'paperback', 17995, 'Y'),
    ('978-87-7286-403-7', 'Søvnens hemmeligheder', 'Louise Dahl', 4, 'paperback', 19995, 'Y'),
    ('978-87-7286-404-4', 'Søvnens hemmeligheder', 'Louise Dahl', 4, 'audiobook', 17995, 'Y'),
    ('978-87-7286-405-1', 'Kunsten at gå', 'Peter Lindberg', 4, 'hardback', 24995, 'Y'),
    ('978-87-7286-406-8', 'Nordisk mad hele året', 'Camilla Nørgaard', 4, 'hardback', 32995, 'Y'),
    ('978-87-7286-407-5', 'Nordisk mad hele året', 'Camilla Nørgaard', 4, 'ebook', 14995, 'Y'),
    ('978-87-7286-408-2', 'Vikingernes verden', 'Rasmus Kjær', 4, 'paperback', 14995, 'N'),
    ('978-87-7286-501-0', 'Introduktion til statistik', 'Mette Vestergaard', 5, 'paperback', 44995, 'Y'),
    ('978-87-7286-502-7', 'Introduktion til statistik', 'Mette Vestergaard', 5, 'ebook', 29995, 'Y'),
    ('978-87-7286-503-4', 'Organisation og ledelse', 'Jens Holm Iversen', 5, 'paperback', 39995, 'Y'),
    ('978-87-7286-504-1', 'Grammatik i praksis', 'Hanne Bech', 5, 'paperback', 34995, 'Y'),
    ('978-87-7286-505-8', 'Grammatik i praksis', 'Hanne Bech', 5, 'ebook', 24995, 'Y'),
    ('978-87-7286-506-5', 'Databaser og SQL', 'Søren Mogensen', 5, 'paperback', 42995, 'Y'),
    ('978-87-7286-507-2', 'Grundbog i psykologi', 'Line Andreasen', 5, 'paperback', 49995, 'Y'),
    ('978-87-7286-508-9', 'Excel for begyndere', 'Søren Mogensen', 5, 'paperback', 19995, 'N')
) as t(isbn, title, author, imprint_id, format, price_ore, in_print_flag);

-- ---------------------------------------------------------------------
-- CUSTOMERS: 2,000 customers with an account in the web shop or the book
-- club (incremental load)
-- About 15 % have no e-mail, and some e-mails are in upper case or padded
-- with spaces (cleaned up in staging).
-- ---------------------------------------------------------------------
create or replace table shop.customers as
with
first_names as (
    select * from (values
        (0, 'Anna'), (1, 'Mads'), (2, 'Sofie'), (3, 'Mikkel'), (4, 'Emma'),
        (5, 'Frederik'), (6, 'Ida'), (7, 'Lucas'), (8, 'Clara'), (9, 'Oliver'),
        (10, 'Freja'), (11, 'William'), (12, 'Laura'), (13, 'Noah'), (14, 'Karla'),
        (15, 'Magnus'), (16, 'Ella'), (17, 'Emil'), (18, 'Josefine'), (19, 'Victor'),
        (20, 'Maja'), (21, 'Christian'), (22, 'Mathilde'), (23, 'Rasmus'), (24, 'Caroline'),
        (25, 'Jonas'), (26, 'Julie'), (27, 'Anders'), (28, 'Line'), (29, 'Søren'),
        (30, 'Mette'), (31, 'Lars'), (32, 'Hanne'), (33, 'Jens'), (34, 'Camilla'),
        (35, 'Peter'), (36, 'Louise'), (37, 'Henrik'), (38, 'Marie'), (39, 'Thomas')
    ) as t(idx, first_name)
),
last_names as (
    select * from (values
        (0, 'Jensen'), (1, 'Nielsen'), (2, 'Hansen'), (3, 'Pedersen'), (4, 'Andersen'),
        (5, 'Christensen'), (6, 'Larsen'), (7, 'Sørensen'), (8, 'Rasmussen'), (9, 'Jørgensen'),
        (10, 'Petersen'), (11, 'Madsen'), (12, 'Kristensen'), (13, 'Olsen'), (14, 'Thomsen'),
        (15, 'Christiansen'), (16, 'Poulsen'), (17, 'Johansen'), (18, 'Møller'), (19, 'Mortensen'),
        (20, 'Knudsen'), (21, 'Jakobsen'), (22, 'Jacobsen'), (23, 'Mikkelsen'), (24, 'Olesen'),
        (25, 'Frederiksen'), (26, 'Laursen'), (27, 'Henriksen'), (28, 'Lund'), (29, 'Schmidt'),
        (30, 'Eriksen'), (31, 'Holm'), (32, 'Kristiansen'), (33, 'Clausen'), (34, 'Simonsen'),
        (35, 'Svendsen'), (36, 'Andreasen'), (37, 'Iversen'), (38, 'Jeppesen'), (39, 'Mogensen')
    ) as t(idx, last_name)
),
zip_codes as (
    select * from (values
        (0, '2200'), (1, '2100'), (2, '2300'), (3, '2400'), (4, '1050'), (5, '2000'),
        (6, '8000'), (7, '8200'), (8, '8210'), (9, '8230'), (10, '8240'),
        (11, '5000'), (12, '5200'), (13, '5220'), (14, '5230'), (15, '5250'),
        (16, '9000'), (17, '9200'), (18, '9210'), (19, '9220'),
        (20, '4000'), (21, '4030'), (22, '4040'), (23, '4130')
    ) as t(idx, zip_code)
),
base as (
    select
        s.n as cust_no,
        cast(abs(hash(cast(s.n as varchar) || 'first_name')) % 40 as integer) as first_name_idx,
        cast(abs(hash(cast(s.n as varchar) || 'last_name')) % 40 as integer) as last_name_idx,
        cast(abs(hash(cast(s.n as varchar) || 'zip')) % 24 as integer) as zip_idx,
        cast(abs(hash(cast(s.n as varchar) || 'email')) % 100 as integer) as email_roll,
        400 + cast(abs(hash(cast(s.n as varchar) || 'created_days')) % 1800 as integer) as created_days_ago,
        360 + cast(abs(hash(cast(s.n as varchar) || 'created_minute')) % 720 as integer) as created_minute
    from (select row_number() over (order by seq4()) as n from table(generator(rowcount => 2000))) as s
),
named as (
    select
        b.cust_no,
        f.first_name,
        l.last_name,
        z.zip_code,
        b.email_roll,
        dateadd(minute, b.created_minute, cast(dateadd(day, -b.created_days_ago, dateadd(day, -2, cast(sysdate() as date))) as timestamp_ntz)) as created_ts,
        replace(replace(replace(lower(f.first_name || '.' || l.last_name), 'æ', 'ae'), 'ø', 'oe'), 'å', 'aa')
            || cast(b.cust_no as varchar) || '@example.dk' as clean_email
    from base as b
    join first_names as f on f.idx = b.first_name_idx
    join last_names as l on l.idx = b.last_name_idx
    join zip_codes as z on z.idx = b.zip_idx
)
select
    cust_no,
    first_name,
    last_name,
    case
        when email_roll < 15 then null
        when email_roll < 19 then upper(clean_email)
        when email_roll < 22 then '  ' || clean_email || ' '
        else clean_email
    end as email,
    zip_code,
    created_ts,
    dateadd(minute, 120, cast(dateadd(day, 1, cast(created_ts as date)) as timestamp_ntz)) as _loaded_at
from named;

-- Planted issue 1: customer 1042 was re-exported after moving (new e-mail and
-- zip code), and the nightly load appended the row instead of updating it.
insert into shop.customers
select
    cust_no,
    first_name,
    last_name,
    'ny.adresse.' || cast(cust_no as varchar) || '@example.dk' as email,
    '8000' as zip_code,
    created_ts,
    dateadd(minute, 120, cast(dateadd(day, -1, cast(sysdate() as date)) as timestamp_ntz)) as _loaded_at
from shop.customers
where cust_no = 1042;

-- ---------------------------------------------------------------------
-- ORDERS: 20,000 orders over the last 365 days (incremental load)
-- ORDER_TS is in UTC. CHANNEL is WEB (the web shop) or BOOK_CLUB.
-- STATUS_CD: P = placed, S = shipped, D = delivered, X = cancelled. Only
-- orders from the last day can still be P or S. Book club orders are
-- cancelled more often, because members can decline the book of the month.
-- ---------------------------------------------------------------------
create or replace table shop.orders as
with
base as (
    select
        s.n as order_no,
        1 + cast(abs(hash(cast(s.n as varchar) || 'customer')) % 2000 as integer) as cust_no,
        cast(abs(hash(cast(s.n as varchar) || 'channel')) % 100 as integer) as channel_roll,
        cast(abs(hash(cast(s.n as varchar) || 'status')) % 100 as integer) as status_roll,
        300 + cast(abs(hash(cast(s.n as varchar) || 'club_minute')) % 660 as integer) as club_minute,
        360 + cast(abs(hash(cast(s.n as varchar) || 'web_minute')) % 1080 as integer) as web_minute,
        364 - cast(floor((s.n - 1) * 365 / 20000) as integer) as days_ago
    from (select row_number() over (order by seq4()) as n from table(generator(rowcount => 20000))) as s
),
with_dates as (
    select
        b.*,
        case when b.channel_roll < 70 then 'WEB' else 'BOOK_CLUB' end as channel,
        dateadd(day, -b.days_ago, dateadd(day, -2, cast(sysdate() as date))) as order_date
    from base as b
)
select
    order_no,
    cust_no,
    case
        when channel = 'WEB' then dateadd(minute, web_minute, cast(order_date as timestamp_ntz))
        else dateadd(minute, club_minute, cast(order_date as timestamp_ntz))
    end as order_ts,
    case
        when days_ago = 0 then
            case
                when status_roll < 35 then 'P'
                when status_roll < 65 then 'S'
                when status_roll < 92 then 'D'
                else 'X'
            end
        when channel = 'WEB' then case when status_roll < 95 then 'D' else 'X' end
        else case when status_roll < 90 then 'D' else 'X' end
    end as status_cd,
    channel,
    dateadd(minute, 120, cast(dateadd(day, 1, order_date) as timestamp_ntz)) as _loaded_at
from with_dates;

-- Planted issue 2: three orders reference a customer (9999) that does not
-- exist in CUSTOMERS.
insert into shop.orders
select
    20000 + s.n as order_no,
    9999 as cust_no,
    dateadd(minute, 555, cast(dateadd(day, -(s.n * 4), dateadd(day, -2, cast(sysdate() as date))) as timestamp_ntz)) as order_ts,
    'D' as status_cd,
    'WEB' as channel,
    dateadd(minute, 120, cast(dateadd(day, 1 - s.n * 4, dateadd(day, -2, cast(sysdate() as date))) as timestamp_ntz)) as _loaded_at
from (select row_number() over (order by seq4()) as n from table(generator(rowcount => 3))) as s;

-- ---------------------------------------------------------------------
-- ORDER_LINES: 1-4 lines per order, most of them for a single copy
-- (incremental load). The shop system scans the ISBN from the barcode, so
-- it has no hyphens here.
-- ---------------------------------------------------------------------
create or replace table shop.order_lines as
with
line_numbers as (
    select * from (values (1), (2), (3), (4)) as t(line_no)
),
titles_in_print as (
    select
        isbn,
        price_ore,
        row_number() over (order by isbn) - 1 as idx
    from shop.titles
    where in_print_flag = 'Y'
),
lines as (
    select
        o.order_no,
        l.line_no,
        o._loaded_at,
        cast(abs(hash(cast(o.order_no * 10 + l.line_no as varchar) || 'title')) % 36 as integer) as title_idx,
        cast(abs(hash(cast(o.order_no * 10 + l.line_no as varchar) || 'qty')) % 100 as integer) as qty_roll
    from shop.orders as o
    join line_numbers as l
        on l.line_no <= 1 + cast(abs(hash(cast(o.order_no as varchar) || 'lines')) % 4 as integer)
)
select
    row_number() over (order by lines.order_no, lines.line_no) as line_id,
    lines.order_no,
    replace(t.isbn, '-', '') as isbn,
    case when lines.qty_roll < 85 then 1 when lines.qty_roll < 97 then 2 else 3 end as qty,
    t.price_ore as unit_price_ore,
    lines._loaded_at
from lines
join titles_in_print as t
    on t.idx = lines.title_idx;

-- ---------------------------------------------------------------------
-- PAYMENTS.TRX_EXPORT_V2: payment transactions from the payment provider
-- One or more transactions per order: some card payments are declined
-- (STATUS = 'FAILED') before a successful one, and some orders are split
-- between a gift card and another method. Book club members often pay by
-- invoice. Amounts are in øre.
-- ---------------------------------------------------------------------
create or replace table payments.trx_export_v2 as
with
order_totals as (
    select
        o.order_no,
        o.order_ts,
        o.channel,
        o.status_cd,
        o._loaded_at,
        sum(l.qty * l.unit_price_ore) as total_ore
    from shop.orders as o
    join shop.order_lines as l
        on l.order_no = o.order_no
    group by o.order_no, o.order_ts, o.channel, o.status_cd, o._loaded_at
),
rolls as (
    select
        t.*,
        cast(abs(hash(cast(t.order_no as varchar) || 'method')) % 100 as integer) as method_roll,
        cast(abs(hash(cast(t.order_no as varchar) || 'split')) % 100 as integer) as split_roll,
        cast(abs(hash(cast(t.order_no as varchar) || 'failed')) % 100 as integer) as failed_roll
    from order_totals as t
),
methods as (
    select
        r.*,
        case
            when r.channel = 'WEB' then
                case
                    when r.method_roll < 45 then 'MOBILEPAY'
                    when r.method_roll < 90 then 'DANKORT'
                    else 'GIFT_CARD'
                end
            when r.method_roll < 50 then 'INVOICE'
            when r.method_roll < 75 then 'DANKORT'
            when r.method_roll < 95 then 'MOBILEPAY'
            else 'GIFT_CARD'
        end as method,
        -- split payments: a 100 or 200 DKK gift card covers part of the amount
        case
            when r.status_cd <> 'X' and r.split_roll < 4 and r.total_ore > 20000 then 20000
            when r.status_cd <> 'X' and r.split_roll < 4 and r.total_ore > 10000 then 10000
            else 0
        end as gift_card_ore
    from rolls as r
),
payments as (
    -- a declined card payment before the successful one
    select
        order_no,
        1 as attempt_no,
        case when method = 'INVOICE' then 'DANKORT' else method end as method,
        total_ore as amount_ore,
        'FAILED' as status,
        dateadd(minute, 1, order_ts) as trx_ts,
        _loaded_at
    from methods
    where status_cd <> 'X' and failed_roll < 8

    union all

    -- the gift card part of a split payment
    select order_no, 2, 'GIFT_CARD', gift_card_ore, 'OK', dateadd(minute, 2, order_ts), _loaded_at
    from methods
    where gift_card_ore > 0 and method <> 'GIFT_CARD'

    union all

    -- the (remaining) successful payment
    select
        order_no,
        3,
        method,
        total_ore - case when method <> 'GIFT_CARD' then gift_card_ore else 0 end,
        'OK',
        dateadd(minute, 3, order_ts),
        _loaded_at
    from methods
    where status_cd <> 'X'

    union all

    -- some cancelled orders have a declined payment attempt
    select
        order_no,
        1,
        case when method = 'INVOICE' then 'DANKORT' else method end,
        total_ore,
        'FAILED',
        dateadd(minute, 1, order_ts),
        _loaded_at
    from methods
    where status_cd = 'X' and failed_roll < 30
)
select
    row_number() over (order by order_no, attempt_no) as trx_id,
    order_no,
    method,
    amount_ore,
    status,
    trx_ts,
    _loaded_at
from payments;

-- ---------------------------------------------------------------------
-- REVIEWS: free-text reader reviews in Danish (only used in bonus exercise 11)
-- Written 3-14 days after a delivered order. Only the reviews written before
-- the last nightly load are included.
-- ---------------------------------------------------------------------
create or replace table shop.reviews as
with
texts as (
    select * from (values
        (0, 'Fantastisk krimi. Jeg kunne ikke lægge den fra mig!'),
        (1, 'Hurtig levering, og bogen var pænt pakket ind.'),
        (2, 'Min søn elsker billedbogen. Vi har læst den hver aften.'),
        (3, 'Nem bestilling, og e-bogen var klar med det samme.'),
        (4, 'Pakken kom en uge for sent.'),
        (5, 'Omslaget var flænget, da bogen kom.'),
        (6, 'Lydbogen stoppede midt i kapitel tre.'),
        (7, 'Jeg fik den forkerte bog tilsendt.'),
        (8, 'Helt fin roman, men lidt for lang.'),
        (9, 'Standard levering, intet at bemærke.'),
        (10, 'God bog, men paperbackudgaven var udsolgt.'),
        (11, 'Handlingen var god, slutningen mindre god.')
    ) as t(idx, review_text)
),
reviewed_orders as (
    select
        o.order_no,
        dateadd(day, 3 + cast(abs(hash(cast(o.order_no as varchar) || 'review_days')) % 12 as integer), o.order_ts) as created_ts,
        cast(abs(hash(cast(o.order_no as varchar) || 'review_text')) % 12 as integer) as text_idx
    from shop.orders as o
    where o.status_cd = 'D'
      and cast(abs(hash(cast(o.order_no as varchar) || 'review')) % 100 as integer) = 0
)
select
    row_number() over (order by r.order_no) as review_id,
    r.order_no,
    t.review_text,
    r.created_ts,
    dateadd(minute, 120, cast(dateadd(day, 1, cast(r.created_ts as date)) as timestamp_ntz)) as _loaded_at
from reviewed_orders as r
join texts as t
    on t.idx = r.text_idx
where r.created_ts < cast(dateadd(day, -1, cast(sysdate() as date)) as timestamp_ntz);

-- ---------------------------------------------------------------------
-- Check: row counts and the newest load per table
-- ---------------------------------------------------------------------
select 'shop.imprints' as table_name, count(*) as row_count, max(_loaded_at) as last_loaded_at from shop.imprints
union all select 'shop.titles', count(*), max(_loaded_at) from shop.titles
union all select 'shop.customers', count(*), max(_loaded_at) from shop.customers
union all select 'shop.orders', count(*), max(_loaded_at) from shop.orders
union all select 'shop.order_lines', count(*), max(_loaded_at) from shop.order_lines
union all select 'shop.reviews', count(*), max(_loaded_at) from shop.reviews
union all select 'payments.trx_export_v2', count(*), max(_loaded_at) from payments.trx_export_v2
order by table_name;
