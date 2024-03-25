--Steps I took during the project: 
-- I imported data on covid deaths from ourworldindata.org into excel.
-- After this I cleaned the data and saved 2 copies with only relevant information for each table. 
-- One with information regarding deaths and other regarding vaccines. 
-- I did this to avoid unnecessary JOIN statements in every query.

-- Selecting the data I am going to be using:
SELECT *
FROM [Portfolio Project]..Covid_Deaths

SELECT Location, Date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..Covid_Deaths

-- I changed the data type from of total deaths and cases from nvarchar255 to float, to then be able to use operators to calculate death percentage:
ALTER TABLE dbo.Covid_Deaths
ALTER COLUMN total_deaths float;

ALTER TABLE dbo.Covid_Deaths
ALTER COLUMN total_cases float;

-- I changed the Date column to date from datetime to remove the time which was redundant as they were all 00:00:00:
ALTER TABLE dbo.Covid_Deaths
ALTER COLUMN Date date;

-- Queries

-- Death percentage within the UK:
SELECT Location, Date, total_cases, new_cases, total_deaths, population, (total_deaths/total_cases)*100 AS death_percentage
FROM [Portfolio Project]..Covid_Deaths
WHERE location like '%United Kingdom%'

-- Infection rate of UK:
SELECT Location, Date, total_cases, new_cases, total_deaths, population, (total_cases/population)*100 AS PercentPopInfected
FROM [Portfolio Project]..Covid_Deaths
WHERE location like '%United Kingdom%'

-- Country with highest percent of cases:
SELECT Location, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopInfected
FROM [Portfolio Project]..Covid_Deaths
GROUP BY location, population
ORDER BY PercentPopInfected DESC

-- Countries with highest death count percentage:
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM [Portfolio Project]..Covid_Deaths
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount DESC
-- I put continent is not NULL, to remove location columns that show the continent totals:

-- Showing death count per continent:
SELECT continent, MAX(total_deaths) as TotalDeaths
FROM [Portfolio Project]..Covid_Deaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeaths DESC

-- Global deaths:
SELECT SUM(max_total_cases) AS global_total_cases
FROM (
SELECT location, MAX(total_cases) AS max_total_cases
FROM [Portfolio Project]..Covid_Deaths
WHERE continent is not NULL
GROUP BY location
) AS subquery;

-- Looking at total population vs vaccinations:
SELECT *
FROM [Portfolio Project]..Covid_Vaccinations

-- Using CTE to work out percent of population vaccinated:
WITH PopvsVac (continent, location, date, population, new_vaccinations, CumulativeVaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccinations
FROM [Portfolio Project]..Covid_Deaths dea
JOIN [Portfolio Project]..Covid_Vaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (CumulativeVaccinations/population)*100 AS PercentVaccinated
FROM PopvsVac

-- Creating and using a temp table:
DROP TABLE if EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date date,
population numeric,
New_vaccinations numeric,
CumulativeVaccinations numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(numeric, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccinations
FROM [Portfolio Project]..Covid_Deaths dea
JOIN [Portfolio Project]..Covid_Vaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date

SELECT *, (CumulativeVaccinations / population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualisations:
USE [Portfolio Project]
GO
CREATE VIEW Deaths_per_continent as
SELECT continent, MAX(total_deaths) as TotalDeaths
FROM [Portfolio Project]..Covid_Deaths
WHERE continent is not NULL
GROUP BY continent

USE [Portfolio Project]
GO
CREATE VIEW PercentInfected as
SELECT Location, Date, total_cases, new_cases, total_deaths, population, (total_cases/population)*100 AS PercentPopInfected
FROM [Portfolio Project]..Covid_Deaths
WHERE location like '%United Kingdom%'