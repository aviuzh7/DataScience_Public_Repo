SELECT *
FROM `portfolio1-314712.sqlcovid.coviddeaths` death
ORDER BY 3,4; 

/* world view of death rate by population */
SELECT location, population, MAX(cast(total_deaths AS INT64)) AS HighestDeathCount, MAX((total_deaths/population))*100 AS MaxDeathRate
FROM `portfolio1-314712.sqlcovid.coviddeaths`
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY MaxDeathRate DESC;
/* Hungary is highest at 0.3%, US is at rank 17 */

/* Continuous count of people vaccinated */
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT64)) OVER (PARTITION BY death.Location 
    ORDER BY death.Location, death.Date) AS RollingPeopleVaccinated
FROM `portfolio1-314712.sqlcovid.coviddeaths` death
INNER JOIN `portfolio1-314712.sqlcovid.vaccine` vac
    ON death.location = vac.location
    AND death.date = vac.date
WHERE death.continent IS NOT NULL;
/* This would give us by date the new vaccines given and the cumulative sum of the 
people vaccinated */

/* Common Table Expression, bigquery has different syntax */
WITH PopvsVac AS (SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT64)) OVER (PARTITION BY death.Location 
    ORDER BY death.Location, death.Date) AS RollingPeopleVaccinated
FROM `portfolio1-314712.sqlcovid.coviddeaths` death
INNER JOIN `portfolio1-314712.sqlcovid.vaccine` vac
    ON death.location = vac.location
    AND death.date = vac.date
WHERE death.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population) * 100 AS RollingVaccinationRate
FROM PopvsVac;
/* Gives the vaccinated rate by population for world */

/* US death rate */
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercent
FROM `portfolio1-314712.sqlcovid.coviddeaths` death
WHERE location like '%States%'
ORDER BY 3,4; 
/* DeathPercent shows the likelihood of dying due to catching covid in the US
    as of May2021, we are hovering around the 1.78% mark */

/* Total cases vs population in the US */
SELECT location, date, Population, total_cases, (total_cases/Population)*100 as InfectionRate
FROM `portfolio1-314712.sqlcovid.coviddeaths` death
WHERE location like '%States%'
ORDER BY 3,4;
/* As of May2021 about 10% of the US population has had Covid-19 */

/* world view of the infection rate */
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, Max((total_cases/Population))*100 AS MaxInfectionRate
FROM `portfolio1-314712.sqlcovid.coviddeaths`
GROUP BY location, population
ORDER BY MaxInfectionRate DESC;
/* Adorra has the highest infectino rate at 17%, US is rank 11 at 10% */

/* Overall death rate : deaths/cases */
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT64)) AS total_deaths,
    SUM(CAST(new_deaths AS INT64))/ SUM(New_Cases)*100 AS DeathPercentage
FROM `portfolio1-314712.sqlcovid.coviddeaths`
WHERE continent IS NOT NULL 
ORDER BY 1,2;
/* By comparing deaths to cases we get a death rate of 2.08% */

/* we could use some of the above in a view for Tableau visualizations */

