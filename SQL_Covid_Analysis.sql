-- SELECT TOP 100
--     location,
--     date,
--     total_cases,
--     new_cases,
--     total_deaths,
--     population
-- FROM
--     CovidDatabase.CovidScheme.CovidDeaths
-- ORDER BY
--     1, 2

-- Likelihood of Dying of Covid (Upon Contracting Covid) in Germany
SELECT
    location,
    date,
    total_cases,
    total_deaths,
    (total_deaths/total_cases)*100 AS Death_Percentage
FROM
    CovidDatabase.CovidScheme.CovidDeaths
WHERE
    location = 'Germany' AND
    continent IS NOT null
ORDER BY
    1, 2

-- Population percentage that has gotten Covid
SELECT
    location,
    date,
    population,
    total_cases,
    CAST((total_cases/population)*100 AS DECIMAL(7,6)) AS Population_Infected_Percentage
FROM
    CovidDatabase.CovidScheme.CovidDeaths
WHERE
    location = 'Germany' AND
    continent IS NOT null
ORDER BY
    1, 2


-- Countries with Highest Infection Rate Compared to Population
SELECT
    location,
    population,
    MAX(total_cases) AS Highest_Infection_Count,
    MAX((total_cases/population))*100 AS Population_Infected_Percentage
FROM
    CovidDatabase.CovidScheme.CovidDeaths
WHERE
    continent IS NOT null
GROUP BY
    location,
    population
ORDER BY
    Population_Infected_Percentage DESC


-- Countries with Highest Death Count per Population
SELECT
    location,
    MAX(total_deaths) AS Total_Death_Count
FROM
    CovidDatabase.CovidScheme.CovidDeaths
WHERE
    continent IS NOT null
GROUP BY
    location
ORDER BY
    Total_Death_Count DESC


-- FILTERING BY CONTINENT #1
SELECT
    continent,
    MAX(total_deaths) AS Total_Death_Count
FROM
    CovidDatabase.CovidScheme.CovidDeaths
WHERE
    continent IS NOT null
GROUP BY
    continent
ORDER BY
    Total_Death_Count DESC


-- FILTERING BY CONTINENT #2
SELECT
    location,
    MAX(total_deaths) AS Total_Death_Count
FROM
    CovidDatabase.CovidScheme.CovidDeaths
WHERE
    continent IS null
GROUP BY
    location
ORDER BY
    Total_Death_Count DESC


-- GLOBAL NUMBERS
SELECT
    location,
    SUM(new_cases) as total_cases,
    SUM(cast(new_deaths as int)) as total_deaths,
--     SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage,
    SUM(cast(new_deaths as float))/SUM(cast(new_cases as float))*100 as DeathPercentage
FROM
    CovidDatabase.CovidScheme.CovidDeaths
WHERE
    continent is not null
GROUP BY
    location
ORDER BY
    1, 2


-- SELECT TOP 100
--     *
-- FROM
--     CovidDatabase.CovidScheme.CovidVaccinations

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(int,vac.new_vaccinations))
        OVER
            (Partition by
                dea.Location
            Order by
                dea.location, dea.Date)
        AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidDatabase.CovidScheme.CovidDeaths dea
JOIN CovidDatabase.CovidScheme.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE
    dea.continent is not null
ORDER BY
        2, 3


SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(int,vac.new_vaccinations))
--     SUM(vac.new_vaccinations)
        OVER
            (Partition by
                dea.Location
            Order by
                dea.location, dea.Date
            )
        AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidDatabase.CovidScheme.CovidDeaths dea
JOIN CovidDatabase.CovidScheme.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE
    dea.continent is not null
ORDER BY
        2, 3


-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS (
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(int,vac.new_vaccinations))
    --     SUM(vac.new_vaccinations)
            OVER
                (Partition by
                    dea.Location
                Order by
                    dea.location, dea.Date
                )
            AS RollingPeopleVaccinated
    --, (RollingPeopleVaccinated/population)*100
    FROM CovidDatabase.CovidScheme.CovidDeaths dea
    JOIN CovidDatabase.CovidScheme.CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE
        dea.continent is not null
    ORDER BY
        2, 3
)
SELECT
    *,
    (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(int,vac.new_vaccinations))
        OVER
            (Partition by
                dea.Location
            Order by
                dea.location, dea.Date
            )
        AS RollingPeopleVaccinated
FROM CovidDatabase.CovidScheme.CovidDeaths dea
JOIN CovidDatabase.CovidScheme.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
-- WHERE
--     dea.continent is not null
-- ORDER BY
--         2, 3

SELECT
    *,
    (RollingPeopleVaccinated/Population)*100
FROM
    #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(int,vac.new_vaccinations))
        OVER
            (Partition by
                dea.Location
            Order by
                dea.location, dea.Date
            )
        AS RollingPeopleVaccinated
FROM CovidDatabase.CovidScheme.CovidDeaths dea
JOIN CovidDatabase.CovidScheme.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE
    dea.continent is not null

