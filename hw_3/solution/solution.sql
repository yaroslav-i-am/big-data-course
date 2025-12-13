-- SQL и получение данных
1. Вывести список всех клиентов (таблица customer).

SELECT * FROM customer;


2. Вывести имена и фамилии клиентов с именем Carolyn.

SELECT first_name, last_name 
FROM customer 
WHERE first_name = 'Carolyn';


3. Вывести полные имена клиентов (имя + фамилия в одной колонке), у которых имя или фамилия содержат подстроку ary (например: Mary, Geary).

SELECT CONCAT(first_name, ' ', last_name) AS full_name
FROM customer
WHERE first_name LIKE '%ary%'
	OR last_name LIKE '%ary%';


4. Вывести 20 самых крупных транзакций (таблица payment).

SELECT *
FROM payment
ORDER BY amount DESC
LIMIT 20;


5. Вывести адреса всех магазинов, используя подзапрос.

SELECT *
FROM address
WHERE address_id IN (
    SELECT address_id
    FROM store
);


6. Для каждой оплаты вывести число, месяц и день недели в числовом формате (Понедельник – 1, Вторник – 2 и т.д.).

SELECT
    EXTRACT(DAY FROM payment_date)::INTEGER AS day,
    EXTRACT(MONTH FROM payment_date)::INTEGER AS month,
    EXTRACT(ISODOW FROM payment_date)::INTEGER AS weekday
FROM payment;


7. Вывести, кто (customer_id), когда (rental_date, приведенная к типу date) и у кого (staff_id) брал диски в аренду в июне 2005 года.

SELECT
    customer_id,
    rental_date::DATE AS rental_date,  -- Влияет только на вывод, а не на фильтрацию
    staff_id
FROM rental
WHERE rental_date >= '2005-06-01'  -- Здесь нет приведений к типу, поэтому этот запрос может использовать индекс.
	AND rental_date < '2005-07-01';


8. Вывести название, описание и длительность фильмов (таблица film), выпущенных после 2000 года, с длительностью от 60 до 120 минут включительно. Показать первые 20 фильмов с наибольшей длительностью.

SELECT title, description, length
FROM film
WHERE length BETWEEN 60 AND 120
	AND release_year > 2000
ORDER BY length DESC
LIMIT 20


9. Найти все платежи (таблица payment), совершенные в апреле 2007 года, стоимость которых не превышает 4 долларов. 
Вывести идентификатор платежа, дату (без времени) и сумму платежа. Отсортировать платежи по убыванию суммы, а при равной сумме — 
по более ранней дате.

SELECT
    payment_id,
    payment_date::DATE AS payment_date,
    amount
FROM payment
WHERE payment_date >= '2007-04-01'
 	AND payment_date < '2007-05-01'
	AND amount <= 4
ORDER BY
    amount DESC,
    payment_date ASC;


10. Показать имена, фамилии и идентификаторы всех клиентов с именами Jack, Bob или Sara, чья фамилия содержит букву «p». 
Переименовать колонки: с именем — в «Имя», с идентификатором — в «Идентификатор», с фамилией — в «Фамилия». Отсортировать 
клиентов по возрастанию идентификатора.

SELECT 
	first_name AS "Имя",
	last_name AS "Фамилия",
	customer_id AS "Идентификатор"
FROM customer
WHERE first_name IN ('Jack', 'Bob', 'Sara')  -- если нужно регистронезависимо, то можно добавить LOWER(), но это не будет использовать индекс. Хорошо бы изначально индекс строить уже с LOWER
	AND last_name ILIKE '%p%'
ORDER BY customer_id ASC;


11. Работа с собственной таблицей студентов
Создать таблицу студентов с полями: имя, фамилия, возраст, дата рождения и адрес. Все поля должны запрещать внесение пустых значений (NOT NULL).
Внести в таблицу одного студента с id > 50.
Просмотреть текущие записи таблицы.
Внести несколько записей одним запросом, используя автоинкремент id.
Снова просмотреть текущие записи таблицы.
Удалить одного выбранного студента.
Вывести полный список студентов.
Удалить таблицу студентов.
Выполнить запрос на выборку из таблицы студентов и вывести его результат (показать, что таблица удалена).

DROP TABLE IF EXISTS students;
CREATE TABLE students (
	id SERIAL PRIMARY KEY,
	first_name TEXT NOT NULL,
	last_name TEXT NOT NULL,
	age INTEGER NOT NULL,
	birth_date DATE NOT NULL,
	address TEXT NOT NULL
);
INSERT 
	INTO students (id, first_name, last_name, age, birth_date, address)
	VALUES (1, 'Александр', 'Иванов', 24, '2005-08-24', 'г. Москва, ул. Ленина, д. 82');  -- Автоинкремент не обновится, если его не обновить вручную. Произойдёт конфликт ID'шников 1 и 1
SELECT setval('students_id_seq', (SELECT MAX(id) FROM students));
SELECT * FROM students;
INSERT INTO students (first_name, last_name, age, birth_date, address)
	VALUES
	    ('Мария', 'Никонова', 19, '1994-07-22', 'г. Севастополь, Нахимовский пр., д. 5'),
	    ('Станислав', 'Сидоров', 21, '2004-11-30', 'г. Новосибирск, ул. Гагарина, д. 66'),
	    ('Екатерина', 'Владимирова', 43, '1972-01-10', 'г. Екатеринбург, ул. Мира, д. 22');
SELECT * FROM students;
DELETE FROM students
	WHERE id = 2;
SELECT * FROM students;
DROP TABLE students;
SELECT * FROM students;



-- JOIN и агрегатные функции
12. Вывести количество уникальных имен клиентов.

SELECT COUNT(DISTINCT first_name) AS unique_names_number
	FROM customer;


13. Вывести 5 самых часто встречающихся сумм оплаты: саму сумму, даты таких оплат, количество платежей с этой суммой и общую сумму этих платежей.

SELECT
	amount,
	ARRAY_AGG(payment_date::DATE) AS payment_dates,
	COUNT(*) AS payment_count,
	SUM(amount) AS total_amount
FROM payment
GROUP BY amount
ORDER BY payment_count DESC, amount DESC
LIMIT 5;


14. Вывести количество ячеек (записей) в инвентаре для каждого магазина.

SELECT 
	store_id, 
	COUNT(*) AS items_count
FROM inventory
GROUP BY store_id


15. Вывести адреса всех магазинов, используя соединение таблиц (JOIN).

SELECT 
	a.address,
	a.address2,
	a.address_id AS address_table_address_id,  -- для примера
	s.address_id AS store_table_address_id	   -- для примера
FROM store s JOIN address a 
	ON s.address_id = a.address_id;


16. Вывести полные имена всех клиентов и всех сотрудников в одну колонку (объединенный список).

SELECT first_name || ' ' || last_name AS full_name
	FROM staff	
UNION 
SELECT first_name || ' ' || last_name AS full_name  -- Проигнорируется, но не ошибка 
	FROM customer


17. Вывести имена клиентов, которые не совпадают ни с одним именем сотрудников (операция EXCEPT или аналог).

SELECT DISTINCT first_name
	FROM customer
EXCEPT
SELECT DISTINCT first_name
	FROM staff
ORDER BY first_name;


18. Вывести, кто (customer_id), когда (rental_date, приведенная к типу date) и у кого (staff_id) брал диски в аренду в июне 2005 года.

SELECT 
	customer_id,
	rental_date::DATE,
	staff_id
FROM rental
WHERE rental_date >= '2005-06-01' AND rental_date < '2005-07-01';  -- Одинарные кавычки для строк, дат, времени, строк и INSERT. Двойные кавычки для идентификаторов объектов (но не всегда).


19. Вывести идентификаторы всех клиентов, у которых 40 и более оплат. Для каждого такого клиента посчитать средний размер транзакции, 
округлить его до двух знаков после запятой и вывести в отдельном столбце.

SELECT 
	customer_id,
	ROUND(AVG(amount), 2) AS average_payment,
	COUNT(*) AS payments_count   -- Для самопроверки
FROM payment
GROUP BY customer_id
--WHERE payments_count > 40    -- Порядок выполнения: 1. FROM → 2. WHERE → 3. GROUP BY → 4. HAVING → 5. SELECT → 6. ORDER BY
--HAVING payments_count > 40   -- SELECT тоже ещё не выполнился!
HAVING COUNT(*) > 40
ORDER BY payments_count ASC


20. Вывести идентификатор актера, его полное имя и количество фильмов, в которых он снялся. Определить актера, снявшегося в 
наибольшем количестве фильмов (группировать по id актера).

SELECT 
	a.actor_id,
	a.first_name || ' ' || a.last_name AS full_name,
	COUNT(*) AS films_count
FROM actor a
JOIN film_actor fa 
ON a.actor_id = fa.actor_id
GROUP BY a.actor_id, first_name, a.last_name
ORDER BY films_count DESC, full_name ASC
LIMIT 1;


21. Посчитать выручку по каждому месяцу работы проката. Месяц должен определяться по дате аренды (rental_date), а не по 
дате оплаты (payment_date). Округлить выручку до одного знака после запятой. Отсортировать строки в хронологическом порядке. 
В отчете должен присутствовать месяц, в который не было выручки (нет данных о платежах).

WITH months AS (
	SELECT GENERATE_SERIES(
		DATE_TRUNC('month', MIN(rental_date)),
		DATE_TRUNC('month', MAX(rental_date)),
		'1 month'
	)::DATE AS month_start
	FROM rental
)
SELECT
	m.month_start AS month,
	COALESCE(ROUND(SUM(p.amount), 1), 0.0) AS revenue
FROM months m
LEFT JOIN rental r ON DATE_TRUNC('month', r.rental_date)::DATE = m.month_start
LEFT JOIN payment p ON r.rental_id = p.rental_id
GROUP BY m.month_start
ORDER BY m.month_start;


22. Найти средний платеж по каждому жанру фильма. Отобразить только те жанры, к которым относится более 60 различных фильмов. 
Округлить средний платеж до двух знаков после запятой и дать понятные названия столбцам. Отсортировать жанры по убыванию среднего платежа.

SELECT
	c.name AS genre,
	ROUND(AVG(p.amount), 2) AS avg_payment
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY c.category_id, c.name
HAVING COUNT(DISTINCT f.film_id) > 60
ORDER BY avg_payment DESC;


23. Определить, какие фильмы чаще всего берут напрокат по субботам. Вывести названия первых 5 самых популярных фильмов. 
При одинаковой популярности отдать предпочтение фильму, который идет раньше по алфавиту.

SELECT
	f.title
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
WHERE EXTRACT(ISODOW FROM r.rental_date) = 6
GROUP BY f.film_id, f.title
ORDER BY COUNT(*) DESC, f.title
LIMIT 5;


-- Оконные функции и простые запросы

24. Для каждой оплаты вывести сумму, дату и день недели (название дня недели текстом).

SELECT
	amount,
	payment_date::DATE AS payment_date,
	TO_CHAR(payment_date, 'Day') AS weekday
FROM payment;


25. (1)
Для каждой оплаты вывести:
	сумму платежа;
	дату платежа;
	день недели, соответствующий дате платежа, в текстовом виде (например: «понедельник», «вторник» и т.п.).

SELECT
	amount AS "Сумма платежа",
	payment_date::DATE AS "Дата платежа",
	CASE EXTRACT(ISODOW FROM payment_date)
		WHEN 1 THEN 'понедельник'
		WHEN 2 THEN 'вторник'
		WHEN 3 THEN 'среда'
		WHEN 4 THEN 'четверг'
		WHEN 5 THEN 'пятница'
		WHEN 6 THEN 'суббота'
		WHEN 7 THEN 'воскресенье'
	END AS "День недели"
FROM payment;

25. (2)
Распределить фильмы по трем категориям в зависимости от длительности:
	«Короткие» — менее 70 минут;
	«Средние» — от 70 минут (включительно) до 130 минут (не включая 130);
	«Длинные» — от 130 минут и более.

SELECT
	film_id,
	title,
	length,
	CASE
		WHEN length < 70 THEN 'Короткие'
		WHEN length >= 70 AND length < 130 THEN 'Средние'
		WHEN length >= 130 THEN 'Длинные'
	END AS category
FROM film
ORDER BY length;

25. (3)
Для каждой категории необходимо:
	посчитать количество прокатов (то есть сколько раз фильмы этой категории брались в аренду);
	посчитать количество фильмов, которые относятся к этой категории и хотя бы один раз сдавались в прокат.
Фильмы, у которых не было ни одного проката, не должны учитываться в подсчете количества фильмов в категории. Продумать, какой тип 
соединения таблиц нужно использовать, чтобы этого добиться.  

SELECT
	category,
	COUNT(*) AS rentals_count,
	COUNT(DISTINCT film_id) AS films_with_rentals_count
FROM (
	SELECT
		f.film_id,
		f.length,
		CASE
			WHEN f.length < 70 THEN 'Короткие'
			WHEN f.length >= 70 AND f.length < 130 THEN 'Средние'
			ELSE 'Длинные'
		END AS category
	FROM film f
	INNER JOIN inventory i ON f.film_id = i.film_id
	INNER JOIN rental r ON i.inventory_id = r.inventory_id
) AS rented_films
GROUP BY category
ORDER BY
	CASE category
		WHEN 'Короткие' THEN 1
		WHEN 'Средние'  THEN 2
		WHEN 'Длинные'  THEN 3
	END;

25. (4)
Для дальнейших заданий считать, что создана таблица weekly_revenue, в которой для каждой недели и года хранится суммарная выручка компании 
за эту неделю (на основании данных о прокатах и платежах).

CREATE TABLE weekly_revenue AS
SELECT
	EXTRACT(YEAR FROM r.rental_date) AS year,
	EXTRACT(WEEK FROM r.rental_date) AS week,
	SUM(p.amount) AS total_revenue
FROM rental r
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY
	EXTRACT(YEAR FROM r.rental_date),
	EXTRACT(WEEK FROM r.rental_date)
ORDER BY year, week;

SELECT * 
FROM weekly_revenue;


26. На основе таблицы weekly_revenue рассчитать накопленную (кумулятивную) сумму недельной выручки бизнеса. 
Вывести все столбцы таблицы weekly_revenue и добавить к ним столбец с накопленной выручкой. Накопленную выручку округлить до целого числа.

SELECT
	year,
	week,
	total_revenue,
	ROUND(SUM(total_revenue) OVER (ORDER BY year, week))::INTEGER AS cumulative_revenue
FROM weekly_revenue
ORDER BY year, week;


27. На основе таблицы weekly_revenue рассчитать скользящую среднюю недельной выручки, используя для расчета три недели: 
предыдущую, текущую и следующую. Вывести всю таблицу weekly_revenue и добавить:  
	столбец с накопленной суммой выручки;
	столбец со скользящей средней недельной выручки.
Скользящую среднюю округлить до целого числа.

SELECT
	year,
	week,
	total_revenue,
	ROUND(SUM(total_revenue) OVER (ORDER BY year, week))::INTEGER AS cumulative_revenue,
	ROUND(AVG(total_revenue) OVER (
		ORDER BY year, week
		ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
	))::INTEGER AS moving_3_weeks_avg
FROM weekly_revenue
ORDER BY year, week;


28. Рассчитать прирост недельной выручки бизнеса в процентах по сравнению с предыдущей неделей.
Прирост в процентах определяется как:  
(текущая недельная выручка – выручка предыдущей недели) / выручка предыдущей недели × 100%.
Вывести всю таблицу weekly_revenue и добавить:
	​​​​​​​столбец с накопленной суммой выручки;
	столбец со скользящей средней;
	столбец с приростом недельной выручки в процентах.

SELECT
	year,
	week,
	total_revenue,
	ROUND(SUM(total_revenue) OVER (ORDER BY year, week))::INTEGER AS cumulative_revenue,
	ROUND(AVG(total_revenue) OVER (
		ORDER BY year, week
		ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
	))::INTEGER AS moving_3_weeks_avg,
	ROUND(
		(total_revenue - LAG(total_revenue, 1) OVER (ORDER BY year, week))
		/ NULLIF(LAG(total_revenue, 1) OVER (ORDER BY year, week), 0)
		* 100,
		2
	) AS revenue_growth_pct
FROM weekly_revenue
ORDER BY year, week;
