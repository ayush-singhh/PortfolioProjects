/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


SELECT *  
FROM CovidDeaths
WHERE continent is NOT NULL
ORDER BY 4

-- Select Data that we are going to be starting with


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio project]..[covidDeaths]
ORDER BY 1,2


-- Total Cases VS Total Deaths
-- Shows liklihood of dying if you contract Covid in your Country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM [Portfolio project]..[CovidDeaths]
WHERE location LIKE '%India%' 
ORDER BY 5 DESC


-- Total Cases vs Population 
-- Shows what percentage of population got infected with Covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS CasesPercentage
FROM [Portfolio project]..[CovidDeaths]
WHERE location LIKE '%India%' 
ORDER BY 3


-- Countries with Highest infection rate compared with Population

SELECT location, population, MAX(total_cases) AS higest_infeaction_count, 
      MAX((total_cases/population)*100) AS higest_infeaction_percentage,
FROM [Portfolio project]..[CovidDeaths]
GROUP BY location, population
ORDER BY 4 DESC


-- Countries with Highest Death count per Population

SELECT location, MAX(total_deaths) AS total_death_count
FROM [Portfolio project]..[CovidDeaths]
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY 2 DESC 


-- BREAKING THINGS DOWN BY CONTINENT

-- Continents with Highest Death count per Population

SELECT location, MAX(total_deaths) AS total_death_count
FROM [Portfolio project]..[CovidDeaths]
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC 


-- Global Death number

SELECT SUM(ts) AS Total_cases, SUM(td) AS Total_deaths, td/ts
FROM (
	SELECT location, MAX(total_cases) ts, MAX(total_deaths) as td
	FROM CovidDeaths
	WHERE continent is NOT NULL
	GROUP BY location
) AS X


-- Total population vs Vaccination
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT cd.continent, cd.location , cd.date, cd.population, cv.new_vaccinations,
	SUM(CAST(new_vaccinations AS BIGINT)) OVER ( PARTITION BY cd.location ORDER BY cd.date) 
	AS total_vaccination_rolling
FROM CovidDeaths AS cd 
JOIN CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL AND cv.location like '%India%' AND cv.new_vaccinations > 1
ORDER BY 1,2,3


-- Using CTE to perform Calculation on Partition By in previous query

WITH tvr (continent,location,date,population,new_vaccinations, total_vaccination_rolling)
	AS 
		(
		SELECT cd.continent, cd.location , cd.date, cd.population, cv.new_vaccinations,
			SUM(CAST(new_vaccinations AS BIGINT)) OVER ( PARTITION BY cd.location ORDER BY cd.date) 
			AS total_vaccination_rolling
		FROM CovidDeaths AS cd 
		JOIN CovidVaccinations AS cv
			ON cd.location = cv.location
			AND cd.date = cv.date
		WHERE cd.continent IS NOT NULL AND cv.location like '%India%' AND cv.new_vaccinations > 1
		)
SELECT *, (total_vaccination_rolling/population)*100 AS total_vaccination_percentage
FROM tvr
ORDER BY 1,2,3


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated  
CREATE TABLE 
 #PercentPopulationVaccinated 
	(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric, 
	new_vaccinations numeric,
	total_vaccination_rundown numeric 
	)

INSERT INTO #PercentPopulationVaccinated
	SELECT cd.continent, cd.location , cd.date, cd.population, cv.new_vaccinations,
		SUM(CAST(new_vaccinations AS BIGINT)) OVER ( PARTITION BY cd.location ORDER BY cd.date) 
		AS total_vaccination_rundown
	FROM CovidDeaths AS cd 
	JOIN CovidVaccinations AS cv
		ON cd.location = cv.location
		AND cd.date = cv.date
	WHERE cd.continent IS NOT NULL AND cv.location like '%India%' AND cv.new_vaccinations > 1
	ORDER BY 1,2,3

SELECT *, (total_vaccination_rundown/population)*100
FROM #PercentPopulationVaccinated 


-- Creating View to store data for later visualizations

CREATE VIEW PercentagePopulationVaccinated AS
	SELECT cd.continent, cd.location , cd.date, cd.population, cv.new_vaccinations, cv.total_vaccinations,
		SUM(CAST(new_vaccinations AS BIGINT)) OVER ( PARTITION BY cd.location ORDER BY cd.date) AS total_vaccination_rundown
	FROM CovidDeaths AS cd 
	JOIN CovidVaccinations AS cv
		ON cd.location = cv.location
		AND cd.date = cv.date 
	WHERE cd.continent IS NOT NULL AND cv.location like '%India%' AND cv.new_vaccinations > 1