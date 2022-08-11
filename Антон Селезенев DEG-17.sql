/*
 * 1. Используя сервис https://supabase.com/ нужно поднять облачную базу данных PostgreSQL.
 * 
 * url: db.cshcqqizqzgvectbinoc.supabase.co
 * port: 5432
 * db: courier_order
 * user: postgres
 * password: anxtRABraNtA
 */

create database courier_order;


/*
 * 2. Для доступа к данным в базе данных должен быть создан пользователь 
 * логин: netocourier
 * пароль: NetoSQL2022
 * права: полный доступ на схему public, к information_schema и pg_catalog права только на чтение. 
*/

create role netology;

grant connect on database courier_order to netology;

grant usage on schema public to netology;
grant create on schema public to netology;
grant select on all tables in schema public to netology;
grant insert on all tables in schema public to netology;
grant update on all tables in schema public to netology;
grant delete on all tables in schema public to netology;

grant usage on schema information_schema to netology;
grant select on all tables in schema information_schema to netology;

grant usage on schema pg_catalog to netology;
grant select on all tables in schema pg_catalog to netology;

create usage netocourier with password 'NetoSQL2022';
grant netology to netocourier;


/*
 * 4. Для генерации uuid необходимо использовать функционал модуля uuid-ossp, который уже подключен в облачной базе.

   5. Для формирования списка значений в атрибуте status используйте create type ... as enum 

 * 3. Должны быть созданы следующие отношения:

courier: --данные по заявкам на курьера
id uuid PK
from_place varchar --откуда
where_place varchar --куда
name varchar --название документа
account_id uuid FK --id контрагента
contact_id uuid FK --id контакта 
description text --описание
user_id uuid FK --id сотрудника отправителя
status enum -- статусы 'В очереди', 'Выполняется', 'Выполнено', 'Отменен'. По умолчанию 'В очереди'
created_date date --дата создания заявки, значение по умолчанию now()

account: --список контрагентов
id uuid PK
name varchar --название контрагента

contact: --список контактов контрагентов
id uuid PK
last_name varchar --фамилия контакта
first_name varchar --имя контакта
account_id uuid FK --id контрагента

user: --сотрудники
id uuid PK
last_name varchar --фамилия сотрудника
first_name varchar --имя сотрудника
dismissed boolean --уволен или нет, значение по умолчанию "нет"
 */

create extension "uuid-ossp";

create type status_type as enum (
	'В очереди',
	'Выполняется',
	'Выполнено',
	'Отменен'
);

create table account (
	id uuid not null default uuid_generate_v4() primary key,
	"name" varchar(100) not null
);

create table contact (
	id uuid not null default uuid_generate_v4() primary key,
	last_name varchar(45) not null,
	first_name varchar(45) not null,
	account_id uuid not null,
	foreign key (account_id) references account (id) on delete cascade
);

create table "user" (
	id uuid not null default uuid_generate_v4() primary key,
	last_name varchar(45) not null,
	first_name varchar(45) not null,
	dismissed boolean not null default false
);

create table courier (
	id uuid not null default uuid_generate_v4() primary key,
	from_place varchar(150) not null,
	where_place varchar(150) not null,
	"name" varchar(50) not null,
	account_id uuid not null,
	contact_id uuid not null,
	description text,
	user_id uuid not null,
	status status_type not null default 'В очереди',
	created_date date not null default now(),
	foreign key (account_id) references account (id) on delete cascade,
	foreign key (contact_id) references contact (id) on delete cascade,
	foreign key (user_id) references "user" (id) on delete cascade
);


/*
 * 6. Для возможности тестирования приложения необходимо реализовать процедуру insert_test_data(value), которая принимает на
 * вход целочисленное значение.
Данная процедура должна внести:
value * 1 строк случайных данных в отношение account.
value * 2 строк случайных данных в отношение contact.
value * 1 строк случайных данных в отношение user.
value * 5 строк случайных данных в отношение courier.
- Генерация id должна быть через uuid-ossp
- Генерация символьных полей через конструкцию
SELECT repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer);
Соблюдайте длину типа varchar. Первый random получает случайный набор символов из строки, второй random дублирует
количество символов полученных в substring.
- Генерация булева типа происходит через 0 и 1 с использованием оператора random.
- Генерацию даты и времени можно сформировать через select now() - interval '1 day' * round(random() * 1000) as timestamp;
 */

--сначала создадим таблицу для иднетификации тестовых данных
create table test_data (
	id uuid not null,
	table_name varchar(10) not null
);

create or replace procedure insert_test_data(value int) as $$
declare i integer;
begin
	for i in 1 .. value
	loop
		with select_cte as (
			select
				uuid_generate_v4() a_id
				, left(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer), 100/2)
		),
		insert_account as(
			insert into account (id, "name")
			select * from select_cte
			returning id
		)
		insert into test_data (id, table_name)
		select id, 'account' from insert_account;
	end loop;
	for i in 1 .. value * 2
	loop
		with select_cte as (
			select
				uuid_generate_v4() c_id
				, left(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer), 45/2)
				, left(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer), 45/2)
				, id
			from account
			order by random() desc
			limit 1
		),
		insert_contact as (
			insert into contact (id, last_name, first_name, account_id)
			select * from select_cte
			returning id
		)
		insert into test_data (id, table_name)
		select id, 'contact' from insert_contact;
	end loop;
	for i in 1 .. value
	loop
		with select_cte as (
			select
				uuid_generate_v4() u_id
				, left(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer), 45/2)
				, left(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer), 45/2)
				, round(random()*1)::int::bool
		),
		insert_user as (
			insert into "user" (id, last_name, first_name, dismissed)
			select * from select_cte
			returning id
		)
		insert into test_data (id, table_name)
		select id, 'user' from insert_user;
	end loop;
	for i in 1 .. value * 5
	loop
		with select_cte as (
			select
				uuid_generate_v4() cr_id
				, left(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer), 150/2)
				, left(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer), 150/2)
				, left(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer), 50/2)
				, a.id
				, c.id
				, repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer)
				, u.id
				, pe.enumlabel::status_type
				, (now() - interval '1 day' * round(random() * 1000))::date
			from account a, contact c, "user" u, pg_catalog.pg_enum pe
			order by random() desc
			limit 1
		),
		insert_courier as (
			insert into courier (id, from_place, where_place, "name", account_id, contact_id, description, user_id, status, created_date)
			select * from select_cte
			returning id
		)
		insert into test_data (id, table_name)
		select id, 'courier' from insert_courier;
	end loop;
end;
$$ language plpgsql;

call insert_test_data(2);


/*
 * Необходимо реализовать процедуру erase_test_data(), которая будет удалять тестовые данные из отношений
 */

create or replace procedure erase_test_data() as $$
begin
	delete from account where id in (select id from test_data where table_name = 'account');
	delete from contact where id in (select id from test_data where table_name = 'contact');
	delete from "user" where id in (select id from test_data where table_name = 'user');
	delete from courier where id in (select id from test_data where table_name = 'courier');
	delete from test_data;
end;
$$ language plpgsql;

call erase_test_data();


/*
 * 8. На бэкенде реализована функция по добавлению новой записи о заявке на курьера:
function add($params) --добавление новой заявки
    {
        $pdo = Di::pdo();
        $from = $params["from"]; 
        $where = $params["where"]; 
        $name = $params["name"]; 
        $account_id = $params["account_id"]; 
        $contact_id = $params["contact_id"]; 
        $description = $params["description"]; 
        $user_id = $params["user_id"]; 
        $stmt = $pdo->prepare('CALL add_courier (?, ?, ?, ?, ?, ?, ?)');
        $stmt->bindParam(1, $from); --from_place
        $stmt->bindParam(2, $where); --where_place
        $stmt->bindParam(3, $name); --name
        $stmt->bindParam(4, $account_id); --account_id
        $stmt->bindParam(5, $contact_id); --contact_id
        $stmt->bindParam(6, $description); --description
        $stmt->bindParam(7, $user_id); --user_id
        $stmt->execute();
    }
Нужно реализовать процедуру add_courier(from_place, where_place, name, account_id, contact_id, description, user_id), 
которая принимает на вход вышеуказанные аргументы и вносит данные в таблицу courier
Важно! Последовательность значений должна быть строго соблюдена, иначе приложение работать не будет.
 */

create or replace procedure add_courier
(from_place text, where_place text, "name" text, account_id text, contact_id text, description text, user_id text)
as $$
declare
	acc text[] = array(select id::text from account);
	cont text[] = array(select id::text from contact);
	usr text[] = array(select id::text from "user");
begin
	if all($1, $2, $3, $4, $5, $7) is not null and $4 = any(acc) and $5 = any(cont) and $7 = any(usr)
	then
		insert into courier (from_place, where_place, "name", account_id, contact_id, description, user_id)
		values ($1::varchar, $2::varchar, $3::varchar, $4::uuid, $5::uuid, $6::text, $7::uuid);
	elseif $4 = any(acc) is false
	then
		raise exception 'Контрагент с id=% отсутствует в базе данных', $4;
	elseif $5 = any(cont) is false
	then
		raise exception 'Контакт контрагента с id=% отсутствует в базе данных', $5;
	elseif $7 = any(usr) is false
	then
		raise exception 'Сотрудник с id=% отсутствует в базе данных', $7;
	else
		raise exception 'Один или несколько параметров принимают пустые значения';
	end if;
end;
$$ language plpgsql;

call add_courier('from', 'where', 'name', '3848ec64-547a-4c92-806a-fac527a09b7c', 'fffcee46-7152-4a6a-b0c1-0b381668b340',
'comment', 'e99b85ba-5808-4e7a-a86b-f28187d3b2b2');


/*
 * 9. На бэкенде реализована функция по получению записей о заявках на курьера: 
static function get() --получение списка заявок
    {
        $pdo = Di::pdo();
        $stmt = $pdo->prepare('SELECT * FROM get_courier()');
        $stmt->execute();
        $data = $stmt->fetchAll();
        return $data;
    }
Нужно реализовать функцию get_courier(), которая возвращает таблицу согласно следующей структуры:
id --идентификатор заявки
from_place --откуда
where_place --куда
name --название документа
account_id --идентификатор контрагента
account --название контрагента
contact_id --идентификатор контакта
contact --фамилия и имя контакта через пробел
description --описание
user_id --идентификатор сотрудника
user --фамилия и имя сотрудника через пробел
status --статус заявки
created_date --дата создания заявки
Сортировка результата должна быть сперва по статусу, затем по дате от большего к меньшему.
Важно! Если названия столбцов возвращаемой функцией таблицы будут отличаться от указанных выше, то приложение работать не будет.
 */

create or replace function get_courier()
returns table (
	id text
	, from_place text
	, where_place text
	, "name" text
	, account_id text
	, account text
	, contact_id text
	, contact text
	, description text
	, user_id text
	, "user" text
	, status text
	, created_date date
)
as $$
begin
	return
	query
	select
		c.id::text "id"
		, c.from_place::text "from_place"
		, c.where_place::text "where_place"
		, c."name"::text "name"
		, a.id::text "account_id"
		, a."name"::text "account"
		, c2.id::text "contact_id"
		, concat(c2.last_name, ' ', c2.first_name)::text "contact"
		, c.description::text "description"
		, u.id::text "user_id"
		, concat(u.last_name, ' ', u.first_name)::text "user"
		, c.status::text "status"
		, c.created_date::date "created_date"
	from courier c 
	join account a on a.id = c.account_id
	join contact c2 on c2.id = c.contact_id
	join "user" u on u.id = c.user_id
	join pg_catalog.pg_enum pe on pe.enumlabel::text = c.status::text
	order by pe.enumsortorder, c.created_date desc;
end;
$$language plpgsql;

select * from get_courier();


/*
 * 10. На бэкенде реализована функция по изменению статуса заявки.
function change_status($params) --изменение статуса заявки
    {
        $pdo = Di::pdo();
        $status = $params["new_status"];
        $id = $params["id"];
        $stmt = $pdo->prepare('CALL change_status(?, ?)');
        $stmt->bindParam(1, $status); --новый статус
        $stmt->bindParam(2, $id); --идентификатор заявки
        $stmt->execute();
    }
Нужно реализовать процедуру change_status(status, id), которая будет изменять статус заявки. 
На вход процедура принимает новое значение статуса и значение идентификатора заявки.
 */

create or replace procedure change_status(status text, id text) as $$
declare
	cour text[] = array(select courier.id::text from courier);
	st text[] = array(select enumlabel::text from pg_catalog.pg_enum pe where enumtypid = 17735);
begin 
	if $2 = any(cour) and $1 = any(st)
	then
		update courier
		set status = $1::status_type
		where courier.id = $2::uuid;
	elseif $2 = any(cour) is false
	then
		raise exception 'Заявка с id=% отсутствует в базе данных', $2;
	elseif $1 = any(st) is false
	then
		raise exception 'Статус % не существует', $1;
	else
		raise exception 'Один или несколько параметров принимают пустые значения';
	end if;
end;
$$ language plpgsql;

call change_status(null, 'c7f6b9d9-539a-47e0-a052-3c9da355472b');


/*
 * 11. На бэкенде реализована функция получения списка сотрудников компании.
static function get_users() --получение списка пользователей
    {
        $pdo = Di::pdo();
        $stmt = $pdo->prepare('SELECT * FROM get_users()');
        $stmt->execute();
        $data = $stmt->fetchAll();
        $result = [];
        foreach ($data as $v) {
            $result[] = $v['user'];
        }
        return $result;
    }
Нужно реализовать функцию get_users(), которая возвращает таблицу согласно следующей структуры:
user --фамилия и имя сотрудника через пробел 
Сотрудник должен быть действующим! Сортировка должна быть по фамилии сотрудника.
 */

create or replace function get_users()
returns table (
	"user" text
)
as $$
begin
	return
	query
	select
		concat(last_name, ' ', first_name)::text "user"
	from "user"
	where dismissed is false
	order by last_name;
end;
$$ language plpgsql;

select * from get_users();


/*
 * 12. На бэкенде реализована функция получения списка контрагентов.
static function get_accounts() --получение списка контрагентов
    {
        $pdo = Di::pdo();
        $stmt = $pdo->prepare('SELECT * FROM get_accounts()');
        $stmt->execute();
        $data = $stmt->fetchAll();
        $result = [];
        foreach ($data as $v) {
            $result[] = $v['account'];
        }
        return $result;
    }
Нужно реализовать функцию get_accounts(), которая возвращает таблицу согласно следующей структуры:
account --название контрагента 
Сортировка должна быть по названию контрагента.
 */

create or replace function get_accounts()
returns table (
	account text
)
as $$
begin
	return
	query
	select
		"name"::text "account"
	from account
	order by "name";	
end;
$$ language plpgsql;

select * from get_accounts();


/*
 * 13. На бэкенде реализована функция получения списка контактов.
function get_contacts($params) --получение списка контактов
    {
        $pdo = Di::pdo();
        $account_id = $params["account_id"]; 
        $stmt = $pdo->prepare('SELECT * FROM get_contacts(?)');
        $stmt->bindParam(1, $account_id); --идентификатор контрагента
        $stmt->execute();
        $data = $stmt->fetchAll();
        $result = [];
        foreach ($data as $v) {
            $result[] = $v['contact'];
        }
        return $result;
    }
Нужно реализовать функцию get_contacts(account_id), которая принимает на вход идентификатор контрагента и возвращает
таблицу с контактами переданного контрагента согласно следующей структуры:
contact --фамилия и имя контакта через пробел 
Сортировка должна быть по фамилии контакта. Если в функцию вместо идентификатора контрагента передан null, 
нужно вернуть строку 'Выберите контрагента'.
 */

create or replace function get_contacts(account_id text)
returns table (
	contact text
)
as $$
begin
	if $1 is null
	then
		return 
		query
		select 'Выберите контрагента';
	else
		return
		query
		select
			concat(c.last_name, ' ', c.first_name)::text "contact"
		from contact c
		where c.account_id = $1::uuid
		order by c.last_name;
	end if;
end;
$$language plpgsql;

select * from get_contacts(null);


/*
 * 14. На бэкенде реализована функция по получению статистики о заявках на курьера: 
static function get_stat() --получение статистики
    {
        $pdo = Di::pdo();
        $stmt = $pdo->prepare('SELECT * FROM courier_statistic');
        $stmt->execute();
        $data = $stmt->fetchAll();
        return $data;
    }
Нужно реализовать представление courier_statistic, со следующей структурой:
account_id --идентификатор контрагента
account --название контрагента
count_courier --количество заказов на курьера для каждого контрагента
count_complete --количество завершенных заказов для каждого контрагента
count_canceled --количество отмененных заказов для каждого контрагента
percent_relative_prev_month -- процентное изменение количества заказов текущего месяца к
предыдущему месяцу для каждого контрагента, если получаете деление на 0, то в результат вывести 0.
count_where_place --количество мест доставки для каждого контрагента
count_contact --количество контактов по контрагенту, которым доставляются документы
cansel_user_array --массив с идентификаторами сотрудников, по которым были заказы со статусом "Отменен" для каждого контрагента
 */

create view courier_statistic as (
with cte_count_courier as (
	select
		cr.account_id 
		, count(*) c
	from courier cr
	group by cr.account_id
),
cte_count_complete as (
	select
		cr.account_id 
		, count(*) c
	from courier cr
	where cr.status = 'Выполнено'
	group by cr.account_id
),
cte_count_canceled as (
	select
		cr.account_id 
		, count(*) c
	from courier cr
	where cr.status = 'Отменен'
	group by cr.account_id
),
cte_count_cur_month as (
	select
		cr.account_id
		, count(*) c
	from courier cr
	where date_trunc('month', cr.created_date) = date_trunc('month', current_date)
	group by cr.account_id
),
cte_count_prev_month as (
	select
		cr.account_id
		, count(*) c
	from courier cr
	where date_trunc('month', cr.created_date) = date_trunc('month', current_date - interval '1' month)
	group by cr.account_id
),
cte_count_where_place as (
	select
		cr.account_id
		, count(distinct cr.where_place) c
	from courier cr
	group by cr.account_id
),
cte_count_contact as (
	select
		cr.account_id
		, count(distinct cr.contact_id) c
	from courier cr
	group by cr.account_id
),
cte_cansel_user_array as (
	select
		cr.account_id 
		, array_agg(distinct cr.user_id) a
	from courier cr
	where cr.status = 'Отменен'
	group by cr.account_id
)
select
	a.id "account_id"
	, a."name" "account"
	, coalesce(c_cour.c, 0) "count_courier"
	, coalesce(c_compl.c, 0) "count_complete"
	, coalesce(c_canc.c, 0) "count_canceled"
	, case
		when coalesce(cpm.c, 0) = 0
			then 0
		else
			round((coalesce(ccm.c, 0)::numeric - coalesce(cpm.c, 0)::numeric) / coalesce(cpm.c, 0)::numeric * 100, 2) 
	end "percent_relative_prev_month"
	, coalesce(cwp.c, 0) "count_where_place"
	, coalesce(cc.c, 0) "count_contact"
	, cua.a "cansel_user_array"
from account a
left join cte_count_courier c_cour on c_cour.account_id = a.id
left join cte_count_complete c_compl on c_compl.account_id = a.id
left join cte_count_canceled c_canc on c_canc.account_id = a.id
left join cte_count_cur_month ccm on ccm.account_id = a.id
left join cte_count_prev_month cpm on cpm.account_id = a.id
left join cte_count_where_place cwp on cwp.account_id = a.id
left join cte_count_contact cc on cc.account_id = a.id
left join cte_cansel_user_array cua on cua.account_id = a.id
);
