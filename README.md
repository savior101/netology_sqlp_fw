## Проектная работа по модулю "Продвинутый SQL"
#### Нетология, курс "Дата-инженер с нуля до middle"
#### Селезенев Антон, группа DEG-17

Задание на выполнение работ в файле _"ТЗ. Итоговое задание Продвинутый SQL_.

**Инструменты:** PostgreSQL 14, DBeaver Community 22.1.3, Ubuntu 20.04.4 LTS, [Supabase](https://supabase.com/).

**Результат работы:**
+ Создана облачная база данных PostgreSQL
+ Создан пользователь БД с правами согласно требований ТЗ
+ DDL создания отношений БД, типов данных
+ Подключен модуль uuid-ossp и использован в качестве генерации id
+ Создано представление courier_statistic с агрегированными данными

Хранимые процедуры для использования в бэкенде приложения:
+ insert_test_data(value) - процедура генерации тестовых данных для наполнения таблиц
+ erase_test_data() - процедура удаления тестовых данных из таблиц
+ add_courier(from_place, where_place, name, account_id, contact_id, description, user_id) - процедура добавления новой записи в таблицу
+ get_courier() - функция вывода данных о заявке
+ change_status(status, id) - процедура изменения статуса заявки
+ get_users() - функция вывода данных о сотрудниках
+ get_accounts() - функция вывода данных о контрагентах
+ get_contacts(account_id) - функция вывода контактных данных по id контрагента

**Код запросов в файле _Антон Селезенев DEG-17.sql_.**
