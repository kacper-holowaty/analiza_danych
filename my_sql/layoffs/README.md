# Projekt - analiza zwolnień pracowników w branży technologicznej w latach 2020 - 2023
W tym projekcie korzystam z zestawu danych dotyczących zwolnień w branży technologicznej w latach 2020 - 2023. Dane dostępne są w pliku **layoffs.csv**. Znajdują się tam pola:
- **company** - nazwa firmy technologicznej
- **location** - region, w którym znajduje się dana firma
- **industry** - obszar w jakim dana firma działa
- **total_laid_off** - całkowita liczba zwolnionych osób
- **percentage_laid_off** - jaki procent pracowników został zwolniony
- **date** - data zwolnienia
- **stage** - etap finansowania firmy
    
  W zestawie danych występują następujące etapy finansowania:
  - ***Seed*** - Pierwsze finansowanie, zwykle od aniołów biznesu, funduszy VC lub akceleratorów.
  - ***Series A*** - Pierwsza duża runda inwestycyjna dla wzrostu firmy.
  - ***Series B*** - Kolejne finansowanie na rozwój (np. ekspansja rynkowa).
  - ***Series C*** - Inwestycje na skalowanie, przejęcia, ekspansję międzynarodową.
  - ***Series D, E, F, G, H, I, J*** - Kolejne etapy finansowania.Zwykle im wyższa litera, tym bardziej dojrzała firma.
  - ***Post-IPO*** - Firma już weszła na giełdę (Initial Public Offering), ale nadal pozyskuje kapitał.
  - ***Private Equity*** - Inwestycje od funduszy private equity, często w celu restrukturyzacji lub dalszego wzrostu.
  - ***Acquired*** - Firma została przejęta przez inną firmę.
  - ***Subsidiary*** - Spółka zależna innej większej firmy.
  - ***Unknown*** - Nieznany etap finansowania.
- **country** - kraj 
- **funds_raised_millions** - oznacza fundusze pozyskane przez firmę (przedstawiono w milionach $)

### Przygotowania
Pierwszą rzeczą, którą należy zrobić jest zaimportowanie i utworzenie tabeli z pliku CSV.

Aby sprawdzić czy wszystko się udało należy wpisać
`SELECT * FROM layoffs;`, aby wyświetlić wszystkie pola z tabeli layoffs. 

Aby nie modyfikować oryginalnych danych, tworzę tabelę **layoffs_staging** będącą kopią tabeli **layoffs**.

```sql
CREATE TABLE layoffs_staging
LIKE layoffs;
 
INSERT INTO layoffs_staging
SELECT * 
FROM layoffs;

SELECT * FROM layoffs_staging;
```

## Oczyszczanie danych

Pierwszym etapem jest oczywiście czyszczenie danych, które obejmowało między innymi usunięcie duplikatów, czyli wierszy, które mają wszystkie wartości takie same, standaryzację danych, poprawienie niektórych pól, które mają wartości NULL lub są puste oraz usunięcie niepotrzebnych rzędów i kolumn.

### Usunięcie duplikatów

Pierwszyk krokiem jest sprawdzenie, czy duplikaty w ogóle występują. W tym celu wykorzystuję CTE (Common Table Expression) oraz tzw. z ang. Window Function: `ROW_NUMBER()` wraz z `OVER()` i `PARTITION BY`, który służą do przypisywania unikalnego numeru rekordu w obrębie grupy na podstawie nazw kolumn przypisanych po `PARTITION BY`. Krótko mówiąc, jeżeli **row_num** będzie większe od 1, to znaczy, że takie pole już występuje i należy je usunąć.  

```sql
WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;
```

Aby móc usunąć zduplikowane wiersze muszę utworzyć nową tabelę **layoffs_staging2** będącą kopią **layoffs_staging** zawierającą dodatkowo pole **row_num** i dopiero teraz, jeżeli pole **row_num** jest większe od 1, to usuwam wiersz z tabeli **layoffs_staging2**.

```sql
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SELECT * 
FROM layoffs_staging2;
```

### Standaryzacja danych

Zauważyłem, że niektóre pola w kolumnie **company** mają niepotrzebne znaki białe (spacje i tabulatory) na początku, więc wykorzystując `TRIM` pozbywam się ich.

```sql
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);
```

Zauważyłem również, że niektóre pola w kolumnie **industry** są do siebie bardzo podobne więc postanowiłem zastąpić, je wspólną, ogólną nazwą.

```sql
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT * 
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```

Następnie sprawdziłem **location** i **country**. W **location** dane wyglądały dobrze, więc nie trzeba było nic zmieniać, natomiast w **country** występowały pola zarówno `United States` jak i `United States.`oznaczające ten sam kraj. Więc postanowiłem ustawić dla nich jedną, wspólną nazwę.

```sql
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
```

Dla kolumny **date** przekonwertowałem wartości z typu *TEXT (string)* na typ *DATE*, a póżniej zmodyfikowałem typ pola w tabeli na `DATE`.

```sql
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y') AS date_as_date_type
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT `date` 
FROM layoffs_staging2
ORDER BY 1;
```

### Poprawianie wartości NULL/pustych pól oraz usuwanie zbędnych kolumn i wierszy

W kolumnie **industry** istnieje kilka pól, które mają wartość NULL lub są puste. Najpierw zamieniam wartości '' (pusty string) na NULL.

```sql
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = '';

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';
```

Potem szukam takich wierszy, gdzie **industry** jest NULL i jeżeli występuje więcej danych odnośnie firmy o tej samej nazwie (kolumna **company** jest taka sama kilka razy), to ustawiam wartość pola **industry**, które było NULL na wartość **industry** z poprzednich wierszy dla tej samej firmy.

A jeżeli po tym występują jeszcze jakieś wartości NULL w polu **industry**, no to zamieniam je na wartość 'Unknown'.

```sql
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

UPDATE layoffs_staging2
SET industry = 'Unknown'
WHERE industry IS NULL;
```

Usunąłem również wiersze, w których zarówno pole **total_laid_off** jak i pole **percentage_laid_off** miały wartość NULL. 

Na podstawie danych, które mam, niestety nie jest możliwe jakiekolwiek wyliczenie wartości któregoś z tych pól, gdyż po prostu w danych brakuje kolumny, która przedstawiałaby liczbę wszystkich pracowników firmy w momencie zwalniania. 

```sql
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; 

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; 
```

W danych zmieniłem również wartości **stage** tam gdzie pola miały wartość NULL. Zmieniłem je na 'Unknown'.

```sql
SELECT *
FROM layoffs_staging2
WHERE stage IS NULL 
OR stage = '';

UPDATE layoffs_staging2
SET stage = 'Unknown'
WHERE stage IS NULL;
```

Sprawdziłem również czy istnieją pola, gdzie **date** jest NULL. Istniało jedno takie pole, więc je usunąłęm.

```sql
SELECT `date`
FROM layoffs_staging2
WHERE `date`IS NULL;

DELETE 
FROM layoffs_staging2
WHERE `date`IS NULL;
```

A na samym końcu usunąłem zbędną w tym momencie kolumnę **row_num**.

```sql
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
```

Oczyszczone dane zostały zapisane w pliku **preprocessed_layoffs.csv**.

## Eksploracyjna analiza danych

Kolejnym etapem jest eksploracyjna analiza danych, która pomaga zrozumieć ich strukturę, znaleźć wzorce, wykryć błędy i określić potencjalne zależności.

Pierwsze zapytanie sprawdza i wyświetla firmy, które w latach 2020 - 2023 zwolniły 100% swoich pracowników ( kolumna **percentage_laid_off**, gdzie wartość 1 oznacza 100% ).   

```sql
SELECT * 
FROM layoffs_staging2
WHERE percentage_laid_off = '1'
ORDER BY total_laid_off DESC;
```

Poniższe zapytanie natomiast wyszukuje i wyświetla firmy, które zwolniły największą liczbę pracowników w tych latach, wraz z łączną liczbą zwolnionych pracowników, posortowanych malejąco. 

```sql
SELECT company, SUM(total_laid_off) AS all_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;
```

Z poniższej tabeli, będącej wynikiem tego zapytania można wyczytać, że firmą, która zwolniła największą liczbę pracowników jest Amazon.

| company     | all_laid_off |
|:-----------:|:------------:|
| Amazon      | 18150        |
| Google      | 12000        |
| Meta        | 11000        |
| Salesforce  | 10090        |
| Microsoft   | 10000        |
| Philips     | 10000        |
| Ericsson    |  8500        |
| Uber        |  7585        |
| Dell        |  6650        |
| Booking.com |  4601        |
| **...**     |  **...**     |

Następnie zrobiłem to samo co powyżej, jednak tym razem wyszukując i wyświetląc na podstawie obszaru w jakim firma działa (kolumna **industry**).

```sql
SELECT industry, SUM(total_laid_off) AS all_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;
```

Z poniższej tabeli można wyczytać, że obszar, w którym dokonano największej ilości zwolnień to obszar konsumencki.

|    industry    | all_laid_off |
|:--------------:|:------------:|
|   Consumer     |    45182     |
|    Retail      |    43613     |
|    Other       |    35789     |
| Transportation |    33748     |
|    Finance     |    28344     |
|  Healthcare    |    25953     |
|     Food       |    22855     |
| **...**        |  **...**     |


W kolejnym przypadku sprawdzałem to samo, ale na podstawie krajów. Z danych wyniknęło, że najwięcej zwolnienień dokonano w USA, a zaraz potem plasują się Indie i Holandia.

```sql
SELECT country, SUM(total_laid_off) AS all_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;
```

|    country     | all_laid_off |
|:-------------:|:------------:|
| United States |    256059    |
|     India     |    35993     |
| Netherlands   |    17220     |
|    Sweden     |    11264     |
|    Brazil     |    10391     |
|   Germany     |    8701      |
| **...**       |  **...**     |

Następnie sprawdzałem to samo, ale tym razem dla lat.

```sql
SELECT YEAR(`date`) AS `YEAR`, SUM(total_laid_off) AS all_laid_off 
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;
```

Dało to następujące wyniki:

| YEAR | all_laid_off |
|:----:|:------------:|
| 2023 |    125677    |
| 2022 |    160661    |
| 2021 |    15823     |
| 2020 |    80998     |


Teraz zapytanie trochę bardziej złożone. Prezentuję tutaj jak zmieniała się liczba zwolnionych pracowników w czasie.

```sql
WITH Rolling_Total AS 
(
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS all_laid_off
FROM layoffs_staging2
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`, all_laid_off, SUM(all_laid_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;
```

A wynik tego zapytania jest następujący:

|   MONTH   | all_laid_off | rolling_total |
|:---------:|:-----------:|:-------------:|
| 2020-03   |    9628     |      9628     |
| 2020-04   |    26710    |     36338     |
| 2020-05   |    25804    |     62142     |
| 2020-06   |    7627     |     69769     |
| 2020-07   |    7112     |     76881     |
|           |   **...**   |               |
| 2022-12   |   10329     |    257482     |
| 2023-01   |   84714     |    342196     |
| 2023-02   |   36493     |    378689     |
| 2023-03   |    4470     |    383159     |


A ostatnim zapytaniem jest zapytanie szeregujące i wyświetlające firmy, które w kolejnych latach zwalniały największą liczbę pracowników.

```sql
WITH Company_Year (company, years, all_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), 
Company_Year_Rank AS 
(
SELECT *,
DENSE_RANK() OVER (PARTITION BY years ORDER BY all_laid_off DESC) AS ranking
FROM Company_Year
)
SELECT *
FROM Company_Year_Rank
WHERE ranking <= 5;
```

Wynik tego zapytania jest następujący:

|   company     | years | all_laid_off | ranking |
|:-------------:|:-----:|:------------:|:-------:|
|     Uber      | 2020  |     7525     |    1    |
| Booking.com   | 2020  |     4375     |    2    |
|   Groupon     | 2020  |     2800     |    3    |
|    Swiggy     | 2020  |     2250     |    4    |
|    Airbnb     | 2020  |     1900     |    5    |
||
|  Bytedance    | 2021  |     3600     |    1    |
|   Katerra     | 2021  |     2434     |    2    |
|    Zillow     | 2021  |     2000     |    3    |
|  Instacart    | 2021  |     1877     |    4    |
| WhiteHat Jr   | 2021  |     1800     |    5    |
||
|     Meta      | 2022  |    11000     |    1    |
|    Amazon     | 2022  |    10150     |    2    |
|    Cisco      | 2022  |     4100     |    3    |
|   Peloton     | 2022  |     4084     |    4    |
|   Carvana     | 2022  |     4000     |    5    |
|   Philips     | 2022  |     4000     |    5    |
||
|    Google     | 2023  |    12000     |    1    |
|  Microsoft    | 2023  |    10000     |    2    |
|   Ericsson    | 2023  |     8500     |    3    |
|    Amazon     | 2023  |     8000     |    4    |
| Salesforce    | 2023  |     8000     |    4    |
|     Dell      | 2023  |     6650     |    5    |

