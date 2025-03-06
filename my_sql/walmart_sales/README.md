# Analiza danych sprzedażowych sieci sklepów Walmart

Projekt polega na znalezieniu interesujących zależności i wyodrębnianiu kluczowych informacji dotyczących danych sprzedażowych sieci Walmart. Dane sprzedażowe dostępne są w pliku **walmart_sales.csv** w repozytorium. Zawiera on historię transakcji dokonywanych przez klientów w trzech różnych obszarach w miastach Mandalay, Yangon i Naypyitaw na przestrzeni trzech miesięcy (styczeń, luty, marzec) w 2019 roku.

Są one oczywiście nieprawdziwe, gdyż Walmart nie posiada swoich sklepów w Mjanma (Birma), a w zestawie danych znajdują się miasta leżące właśnie w tym państwie.

### Dane zawierają następujące kolumny:
- **invoice_id** - unikalny identyfikator transakcji 
- **branch** - obszar, w którym znajduje się sklep, w danych jest on przedstawiony po prostu jako A, B lub C
- **city** - miasto, w którym znajduje się sklep
- **customer_type** - typ klienta, przyjmuje wartości: *'Member'* - posiadacz karty stałego klienta oraz *'Normal'* - zwykły klient
- **gender** - płeć klienta
- **product_line** - kategoria sprzedanego produktu
- **unit_price** - cena sprzedanego produktu
- **quantity** - liczba sprzedanych produktów
- **tax_pct** - procent podatku przy zakupie produktu
- **total** - łączny koszt zakupów `(cena * liczba produktów) + VAT`
- **date** - data dokonania transakcji
- **time** - godzina dokonania transakcji
- **payment** - w jaki sposób zapłacono (*'Cash'*, *'Credit card'*, *'Ewallet'*)
- **cogs** - Cost of Goods Sold, czyli koszt sprzedanych towarów, jest to miara określająca całkowite koszty związane z produkcją lub zakupem towarów, które zostały sprzedane
- **gross_margin_pct** - procent przychodów
- **gross_income** - przychód uzyskany po sprzedaży produktów
- **rating** - ocena transakcji przez klienta

## Stworzenie tabeli

Na początek należy utworzyć tabelę, a następnie zaimportować dane z pliku **walmart_sales.csv**. Właściwości `NOT NULL` przy tworzeniu kolumn sprawiają, że niemożliwe jest dodanie nowego wiersza do tabeli jeżeli choć jedno z pól ma wartość NULL. Sprawia to, że nie trzeba w późniejszych etapach oczyszczać tabeli właśnie z takich pól.

```sql
CREATE TABLE IF NOT EXISTS sales(
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT(6,4) NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT(11,9),
    gross_income DECIMAL(12, 4),
    rating FLOAT(2, 1)
);

SELECT * FROM sales;
```

## Feature engineering

Kolejnym etapem jest feature engineering, czyli proces tworzenia nowych cech. W moim przypadku jest to po prostu stworzenie i dodanie nowych kolumn do tabeli, które ułatwią przyszłą analizę.

Za pomocą poniższego kodu dodaję do tabeli kolumnę **time_of_the_day** informującą o jakiej porze dnia dokonano transakcji. Jej wartości ustawiono na podstawie pola **time** w tej tabeli.

```sql
SELECT 
	time,
	(CASE
		WHEN `time` BETWEEN '06:00:00' AND '11:59:59' THEN 'Morning'
        WHEN `time` BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon'
        WHEN `time` BETWEEN '18:00:00' AND '21:59:59' THEN 'Evening'
        ELSE 'Night'
	END) AS time_of_the_day
FROM sales;

ALTER TABLE sales ADD COLUMN time_of_the_day VARCHAR(10);

UPDATE sales
SET time_of_the_day = (
	CASE
		WHEN `time` BETWEEN '06:00:00' AND '11:59:59' THEN 'Morning'
        WHEN `time` BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon'
        WHEN `time` BETWEEN '18:00:00' AND '21:59:59' THEN 'Evening'
        ELSE 'Night'
	END
);
```

Następnie stworzyłem kolumnę **day_name**, oznaczającą nazwę dnia tygodnia i ustawiłem wartości w niej na podstawie pola **date**.  

```sql
SELECT 
	`date`,
	DAYNAME(`date`) AS day_name
FROM sales;

ALTER TABLE sales ADD COLUMN day_name VARCHAR(10);

UPDATE sales
SET day_name = DAYNAME(`date`);
```

Na podstawie pola **date** ustawiłem również wartości w kolejnej kolumnie **month_name** oznaczającej nazwę miesiąca, w którym dokonano transakcji. Następnie wyświetliłem wszystkie wartości z tabeli, aby upewnić się, czy wszystkie nowe kolumny zostały poprawnie utworzone, a ich pola mają poprawne wartości.

```sql
SELECT 
	`date`,
    MONTHNAME(`date`) AS month_name
FROM sales;

ALTER TABLE sales ADD COLUMN month_name VARCHAR(10);

UPDATE sales
SET month_name = MONTHNAME(`date`);

SELECT * FROM sales;
```

## Eksploracyjna analiza danych (EDA)

Na początku wyświetlam wszystkie kategorie produktów dostępnych w sprzedaży.

```sql
SELECT DISTINCT product_line
FROM sales;
```

| product_line           |
|:----------------------:|
| Food and beverages     |
| Health and beauty      |
| Sports and travel      |
| Fashion accessories    |
| Home and lifestyle     |
| Electronic accessories |

##

Poniższy kod szereguje i wyświetla w jaki sposób i w jakiej ilości dokonywano płatności za zakupy. 

```sql
SELECT payment, COUNT(payment) AS num_of_payments
FROM sales
GROUP BY payment
ORDER BY num_of_payments DESC;
```

Można wyczytać, że najwięcej płatności dokonano za pomocą gotówki.

| payment     | num_of_payments|
|:-----------:|:--------------:|
| Cash        | 344 |
| Ewallet	    | 342 |
| Credit card	| 309 |

##

Kolejną rzeczą jaką zrobiłem, było uszeregowanie według ilości sprzedanych produktów każdej kategorii. 

```sql
SELECT product_line, SUM(quantity) AS total_sold
FROM sales
GROUP BY product_line
ORDER BY total_sold DESC;
```

Można wyczytać, że najczęściej sprzedają się wszelkiego rodzaju akcesoria elektroniczne.

|    product_line    | total_sold |
|:------------------:|:---------:|
| Electronic accessories |   961   |
|  Food and beverages   |   952   |
|  Home and lifestyle   |   911   |
|   Sports and travel   |   902   |
| Fashion accessories  |   902   |
|  Health and beauty   |   844   |

##

Następnie sprawdziłem, w którym miesiącu sklep zarobił ze sprzedaży produktów najwięcej. 

```sql
SELECT 
	month_name AS month, 
    ROUND(SUM(total), 2) AS total_revenue, 
	SUM(cogs) AS cogs,
    ROUND(SUM(gross_income), 2) AS gross_income
FROM sales
GROUP BY month_name
ORDER BY gross_income DESC;
```

|   month  | total_revenue |    cogs    | gross_income |
|:--------:|:-------------:|:----------:|:------------:|
| January  |  116291.87    | 110754.16  |   5537.71  |
|  March   |  108867.15    | 103683.00  |   5184.15  |
| February |   95727.38    |  91168.93  |   4558.45  |

##

Sprawdziłem również, który typ sprzedawanych produktów przynosi największe przychody. 

```sql
SELECT 
	product_line, 
    ROUND(SUM(total), 2) AS total_revenue,
    SUM(cogs) AS cogs,
    ROUND(SUM(gross_income), 2) AS gross_income
FROM sales
GROUP BY product_line
ORDER BY gross_income DESC;
```

Jak można odczytać z poniższej tabeli, największy przychód firma osiąga ze sprzedaży produktów spożywczych.

|      product_line      | total_revenue |   cogs   | gross_income |
|:----------------------:|:-------------:|:--------:|:------------:|
|  Food and beverages   |   56144.84    | 53471.28 |    2673.56   |
| Fashion accessories  |   54305.90    | 51719.90 |    2586.00   |
|  Sports and travel   |   53936.13    | 51367.74 |    2568.39   |
| Home and lifestyle   |   53861.91    | 51297.06 |    2564.85   |
| Electronic accessories |   53783.24    | 51222.13 |    2561.11   |
|  Health and beauty   |   48854.38    | 46527.98 |    2326.40   |

##

Jeżeli uszereguję przychody według miast i obszarów, gdzie sklepy się znajdują, to zapytanie będzie wyglądać następująco.

```sql
SELECT 
	city, 
    branch,
    ROUND(SUM(total), 2) AS total_revenue,
    SUM(cogs) AS cogs,
    ROUND(SUM(gross_income), 2) AS gross_income
FROM sales
GROUP BY city, branch
ORDER BY total_revenue DESC;
```

Można odczytać, że największe przychody sklep zanotował w mieście Naypyitaw.

|     city     | branch | total_revenue |   cogs   | gross_income |
|:-----------:|:------:|:-------------:|:--------:|:------------:|
|  Naypyitaw  |   C    |   110490.78   | 105229.31 |    5261.47   |
|   Yangon    |   A    |   105861.01   | 100820.01 |    5041.00   |
|  Mandalay   |   B    |   104534.61   |  99556.77 |    4977.84   |

##

Następne zapytanie sprawdza, który rodzaj produktów objęty jest największym podatkiem.

```sql
SELECT 
	product_line,
    AVG(tax_pct) AS avg_tax
FROM sales
GROUP BY product_line
ORDER BY avg_tax DESC;
```

|      product_line      |  avg_tax  |
|:----------------------:|:--------:|
| Home and lifestyle     |  16.0303 |
| Sports and travel      |  15.7570 |
| Health and beauty      |  15.4066 |
| Food and beverages     |  15.3653 |
| Electronic accessories |  15.1545 |
| Fashion accessories    |  14.5281 |

##

Kolejne zapytanie odnosi się do tego jakie rodzaje produktów i w jakiej ilości kupują klienci z podziałem na płeć.

```sql
SELECT 
	gender,
    product_line,
    COUNT(gender) AS total_number
FROM sales
GROUP BY gender, product_line
ORDER BY 1, 3 DESC;
```

Z poniższej tabeli wynika, że kobiety najwięcej produktów kupują z kategorii akcesoriów modowych. Natomiast mężczyźni kupują najwięcej produków z kategorii 'Zdrowie i uroda', z tej, która jest najmniej popularna wśród kobiet.  

|  gender  |      product_line      | total_number |
|:--------:|:----------------------:|:------------:|
| Female   | Fashion accessories    |      96      |
| Female   | Food and beverages     |      90      |
| Female   | Sports and travel      |      86      |
| Female   | Electronic accessories |      83      |
| Female   | Home and lifestyle     |      79      |
| Female   | Health and beauty      |      63      |
|||
| Male     | Health and beauty      |      88      |
| Male     | Electronic accessories |      86      |
| Male     | Food and beverages     |      84      |
| Male     | Fashion accessories    |      82      |
| Male     | Home and lifestyle     |      81      |
| Male     | Sports and travel      |      77      |

##

Najlepiej ocenianymi przez klientów transakcjami były transakcje obejmujące zakupy spożywcze.

```sql
SELECT 
	ROUND(AVG(rating), 2) AS avg_rating,
    product_line
FROM sales
GROUP BY product_line
ORDER BY avg_rating DESC;
```

| avg_rating |      product_line      |
|:----------:|:----------------------:|
|    7.11    | Food and beverages     |
|    7.03    | Fashion accessories    |
|    6.98    | Health and beauty      |
|    6.91    | Electronic accessories |
|    6.86    | Sports and travel      |
|    6.84    | Home and lifestyle     |

##

A teraz zapytanie określające w jaki dzień tygodnia oraz o jakiej porze dnia najczęściej dokonywano transakcji.

```sql
SELECT 
    day_name, 
    time_of_the_day, 
    COUNT(*) AS number_of_sales
FROM sales
GROUP BY day_name, time_of_the_day
ORDER BY FIELD(day_name, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), number_of_sales DESC;
```

Z poniższej tabeli, będącej wynikiem tego zapytanie można odczytać, że klienci zakupy robili najczęściej po południu (godzina od 12:00 do 18:00), a jeżeli chodzi o dzień tygodnia, to tutaj statystycznie najwięcej zakupów zostało zrobionych w sobotę.

| day_name  | time_of_the_day | number_of_sales |
|:---------:|:---------------:|:---------------:|
| Monday    | Afternoon       |       75        |
| Monday    | Evening         |       29        |
| Monday    | Morning         |       20        |
|||
| Tuesday   | Afternoon       |       71        |
| Tuesday   | Evening         |       51        |
| Tuesday   | Morning         |       36        |
|||
| Wednesday | Afternoon       |       80        |
| Wednesday | Evening         |       39        |
| Wednesday | Morning         |       22        |
|||
| Thursday  | Afternoon       |       76        |
| Thursday  | Morning         |       33        |
| Thursday  | Evening         |       29        |
|||
| Friday    | Afternoon       |       73        |
| Friday    | Evening         |       36        |
| Friday    | Morning         |       29        |
|||
| Saturday  | Afternoon       |       81        |
| Saturday  | Evening         |       55        |
| Saturday  | Morning         |       28        |
|||
| Sunday    | Afternoon       |       69        |
| Sunday    | Evening         |       41        |
| Sunday    | Morning         |       22        |

## 

Kolejne zapytanie w anlizie określa jaki rodzaj klienta (posiadacz karty stałego klienta lub zwykły klient) oraz klient jakiej płci wydał na swoje zakupy najwięcej.

```sql
SELECT
	customer_type,
    gender,
    COUNT(*) AS number_of_sales,
    ROUND(SUM(total), 2) AS total_revenue
FROM sales
GROUP BY customer_type, gender
ORDER BY total_revenue DESC;
```

Z poniższej tabeli wynika, że statystycznie to kobiety wydawały najwięcej na swoje zakupy. 

| customer_type | gender | number_of_sales | total_revenue |
|:-------------:|:------:|:---------------:|:-------------:|
| Member        | Female |       259       |   87548.60    |
| Normal        | Female |       238       |   78842.33    |
| Normal        | Male   |       258       |   78418.97    |
| Member        | Male   |       240       |   76076.50    |

## 

Poniższe zapytanie wyświetla ile transakcji z podziałem na miasta zostało dokonanych przez kobiety, a ile przez mężczyzn.

```sql
SELECT
	city,
	gender,
    COUNT(*) AS number_of_sales
FROM sales
GROUP BY gender, city
ORDER BY 1, 3 DESC;
```

|   city    | gender | number_of_sales |
|:---------:|:------:|:---------------:|
| Mandalay  | Male   |       169       |
| Mandalay  | Female |       160       |
| Naypyitaw | Female |       177       |
| Naypyitaw | Male   |       150       |
| Yangon    | Male   |       179       |
| Yangon    | Female |       160       |

## 

Kolejne zapytanie przedstawia jak klienci oceniali swoje zakupy w zależności od pory dnia z podziałem na miasta.

```sql
SELECT
	city,
	time_of_the_day,
    ROUND(AVG(rating), 3) AS avg_rating
FROM sales
GROUP BY city, time_of_the_day
ORDER BY city, avg_rating DESC;
```

Trudno wskazać jakiś charakterystyczny schemat przyznawania ocen przez klientów w zależności od pory dnia, ale można zauważyć, że oceną są znacznie niższe w miejscowości Mandalay.

|   city    | time_of_the_day | avg_rating |
|:---------:|:--------------:|:----------:|
| Mandalay  | Morning        |   6.838    |
| Mandalay  | Afternoon      |   6.787    |
| Mandalay  | Evening        |   6.766    |
| Naypyitaw | Evening        |   7.092    |
| Naypyitaw | Afternoon      |   7.079    |
| Naypyitaw | Morning        |   6.975    |
| Yangon    | Afternoon      |   7.041    |
| Yangon    | Morning        |   7.005    |
| Yangon    | Evening        |   6.979    |

## 

Ostatnie zapytanie natomiast sprawdza w jaki sposób klienci oceniają swoje zakupy w zależności od dnia tygodnia. Statystycznie najwyższe oceny wystawiane były w poniedziałki i piątki.

```sql
SELECT
	day_name,
    ROUND(AVG(rating), 3) AS avg_rating
FROM sales
GROUP BY day_name
ORDER BY avg_rating DESC;
```

| day_name  | avg_rating |
|:---------:|:----------:|
| Monday    |   7.131    |
| Friday    |   7.055    |
| Tuesday   |   7.003    |
| Sunday    |   6.989    |
| Saturday  |   6.902    |
| Thursday  |   6.890    |
| Wednesday |   6.760    |
