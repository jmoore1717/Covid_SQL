SELECT *
FROM PortfolioProject..CovidDeaths_2
WHERE continent is not NULL
ORDER BY 3,4

-- SELECT *
-- FROM PortfolioProject..CovidVaccinations
-- ORDER BY 3,4 

-- select the data that we're going to be using  
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths_2
WHERE continent is not NULL
ORDER BY 1,2

-- looking at the total cases vs total deaths
-- shows the likelihood of dying if you contract covid in your contry
SELECT [location], [date], total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths_2
WHERE continent is not NULL
ORDER BY 1,2

-- looking at the total cases vs total deaths in the US
-- shows the likelihood of dying if you contract covid in your contry
SELECT [location], [date], total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths_2
WHERE continent is not NULL
and [location] LIKE '%states%'
ORDER BY 1,2

-- Looking at the total cases vs the population
-- shows what percentage of population got covid
SELECT location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths_2
WHERE location LIKE '%Canada'
and continent is not NULL
ORDER BY 1,2

-- Looking at countries with highest infection rate relative to population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths_2
WHERE continent is not NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing the countries with the highest death percentage, MAX is an example of an aggregate function
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths_2
WHERE continent is not NULL
GROUP BY [location]
ORDER BY TotalDeathCount DESC

-- Let's break things down by continent now instead
-- Showing the continents with the highest death counts
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths_2
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC
-- Doesn't look like Canada has been included in North America, but oh well

-- Global numbers
SELECT date, SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths_2
WHERE continent IS NOT NULL
GROUP BY [date]
ORDER BY 1,2

-- Joining two tables on laction and date
-- Looking at total population vs vaccinations
-- CONVER(int, column_name) - converting data types
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, -- specifying which table you want to pull from 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100 -> can't use a column that you just created to perform calculations
-- so we use a CTE
FROM PortfolioProject..CovidDeaths_2 dea 
JOIN PortfolioProject..CovidVaccinations vac -- adding shortened names
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Using CTE
 WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
 AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, -- specifying which table you want to pull from 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100 -> can't use a column that you just created to perform calculations
-- so we use a CTE
FROM PortfolioProject..CovidDeaths_2 dea 
JOIN PortfolioProject..CovidVaccinations vac -- adding shortened names
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3 
)

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac

-- Temp table
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating view to store data for later visualizations
CREATE View PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths_2 dea 
JOIN PortfolioProject..CovidVaccinations vac 
    ON dea.location = vac.location
    AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL

-- views are permanent tables that you can now refer to 
SELECT *
FROM PercentPopulationVaccinated