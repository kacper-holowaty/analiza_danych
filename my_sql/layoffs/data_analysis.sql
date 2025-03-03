-- EXPLORATORY DATA ANALYSIS

SELECT * FROM layoffs_staging2;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

SELECT * 
FROM layoffs_staging2
WHERE percentage_laid_off = '1'
ORDER BY total_laid_off DESC;

SELECT company, SUM(total_laid_off) AS all_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

SELECT industry, SUM(total_laid_off) AS all_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

SELECT country, SUM(total_laid_off) AS all_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

SELECT YEAR(`date`) AS `YEAR`, SUM(total_laid_off) AS all_laid_off 
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

SELECT stage, SUM(total_laid_off) AS all_laid_off
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;


SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS all_laid_off
FROM layoffs_staging2
GROUP BY `MONTH`
ORDER BY 1 ASC;


WITH Rolling_Total AS 
(
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS all_laid_off
FROM layoffs_staging2
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`, all_laid_off, SUM(all_laid_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;


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