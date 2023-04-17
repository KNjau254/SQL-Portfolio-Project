SELECT *
FROM PortfolioProject..CovVax
ORDER BY 3, 4


--SELECT *
--FROM PortfolioProject..Cov19_Deaths
--ORDER BY 3, 4

 --Selecting Data to be used
 
 SELECT Location, date, total_cases, new_cases, total_deaths, population
 From PortfolioProject..Cov19_Deaths
 Where continent is not null
 Order by 1,2

 --Total Cases vs Total Deaths
 --DeathPercntg shows probability of dying if you contract Covid19 in my Country
 SELECT Location, date, total_cases, total_deaths, CAST(total_deaths AS decimal)/CAST(total_cases AS decimal)*100 as DeathPercntg
 From PortfolioProject..Cov19_Deaths
 Where location like '%Kenya%' and continent is not null
 Order by 1,2


 --Total Cases vs Population
 SELECT Location, date, Population, total_cases, CAST(total_cases AS decimal)/CAST(Population AS decimal)*100 as Incidence_rate
 From PortfolioProject..Cov19_Deaths
 Where location like '%Kenya%' 
 Order by 1,2


 --Countries with Highest Infection Rate compared to Population
SELECT Location, Population,  MAX(total_cases), CAST(MAX(total_cases) AS decimal)/CAST(Population AS decimal)*100 as HighestInfection_rate
FROM PortfolioProject..Cov19_Deaths
 Where continent is not null
GROUP BY Location, Population
ORDER BY HighestInfection_rate desc

--Countries with Highest Death Count per Population
SELECT Location, MAX(Total_deaths) as TotalDeathCount
FROM PortfolioProject..Cov19_Deaths
Where continent is not null
GROUP BY Location
ORDER BY TotalDeathCount desc 

--Focusing on Continent
--Continent with Highest Death Count per Population
SELECT location, MAX(Total_deaths) as TotalDeathCount
FROM PortfolioProject..Cov19_Deaths
WHERE continent IS NULL AND location NOT IN ('Upper middle income', 'Lower middle income', 'World', 'Low income', 'High income')
GROUP BY location
ORDER BY TotalDeathCount DESC --The Order by function didn't, will check out why later on as it's not important at the moment

--Global numbers
SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPerc
FROM PortfolioProject..Cov19_Deaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--RELATING TO COvVAX Numbers
--Getting our initial Table
SELECT*
FROM PortfolioProject..Cov19_Deaths Death
JOIN PortfolioProject..CovVax Vax
ON Death.location = Vax.location
and Death.date = Vax.date

--Total Population vs Vaccinations including Cumulative Vaccinations per Country
SELECT Death.continent, Death.location, Death.date, Death.population, Vax.new_vaccinations, SUM(CONVERT(BIGINT, Vax.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date)
FROM PortfolioProject..Cov19_Deaths Death
JOIN PortfolioProject..CovVax Vax
ON Death.location = Vax.location
and Death.date = Vax.date
WHERE Death.continent IS NOT NULL
ORDER BY 2,3


--Method I Making use of a CTE

WITH POPvsVAC (continent, Location, Date, Population, New_Vaccinations, RunningTotalVax) --No of Columns in CTE should be same in the table
as
(
SELECT Death.continent, Death.location, Death.date, Death.population, Vax.new_vaccinations, SUM(CONVERT(BIGINT, Vax.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS RunningTotalVax_Perc
FROM PortfolioProject..Cov19_Deaths Death
JOIN PortfolioProject..CovVax Vax
ON Death.location = Vax.location
and Death.date = Vax.date
WHERE Death.continent IS NOT NULL
--ORDER BY 2,3
)

SELECT *, (RunningTotalVax/Population)*100 AS PercentPopulationVaccinated
FROM POPvsVAC



--Checking running % Population of Vaccinated people 
WITH POPvsVAC (continent, Location, Date, Population, New_Vaccinations, RunningTotalVax) --No of Columns in CTE should be same in the table
as
(
SELECT Death.continent, Death.location, Death.date, Death.population, Vax.new_vaccinations, SUM(CONVERT(BIGINT, Vax.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) RunningTotalVax
FROM PortfolioProject..Cov19_Deaths Death
JOIN PortfolioProject..CovVax Vax
ON Death.location = Vax.location
and Death.date = Vax.date
WHERE Death.continent IS NOT NULL AND Death.location LIKE '%Kenya%'
--ORDER BY 2,3
)

SELECT *, (RunningTotalVax/Population)*100 AS RunningTotalVax_Perc_Pop
FROM POPvsVAC


--Method II by Creating a Temp Table called #PercPopulationVax
DROP TABLE IF EXISTS #PercPopulationVax --This will drop the table already exists, the script can drop it and recreate it with the correct structure and data. If the table does not exist, the script can create it from scratch.

CREATE TABLE #PercPopulationVax
(
Continent nvarchar(255),
Location nvarchar(100),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RunningTotalVax numeric,
)


INSERT INTO #PercPopulationVax
SELECT Death.continent, Death.location, Death.date, Death.population, Vax.new_vaccinations, SUM(CONVERT(BIGINT, Vax.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) RunningTotalVax
FROM PortfolioProject..Cov19_Deaths Death
JOIN PortfolioProject..CovVax Vax
ON Death.location = Vax.location
and Death.date = Vax.date
WHERE Death.continent IS NOT NULL


SELECT *, (RunningTotalVax/Population)*100 AS RunningTotalVax_Perc_Pop
FROM #PercPopulationVax


--Creating View for later use in Visualization
--View 1
CREATE VIEW PercPopulationVax as 
SELECT Death.continent, Death.location, Death.date, Death.population, Vax.new_vaccinations, SUM(CONVERT(BIGINT, Vax.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) RunningTotalVax
FROM PortfolioProject..Cov19_Deaths Death
JOIN PortfolioProject..CovVax Vax
ON Death.location = Vax.location
and Death.date = Vax.date
WHERE Death.continent IS NOT NULL


--View 2
CREATE VIEW TotalDeath AS
SELECT Location, MAX(Total_deaths) as TotalDeathCount
FROM PortfolioProject..Cov19_Deaths
Where continent is not null
GROUP BY Location

--View 3
CREATE VIEW DeathPerc_Ke AS
SELECT Location, date, total_cases, total_deaths, CAST(total_deaths AS decimal)/CAST(total_cases AS decimal)*100 as DeathPercntg
From PortfolioProject..Cov19_Deaths
Where location like '%Kenya%' and continent is not null

CREATE VIEW DeathPerc_Ke AS
SELECT Location, date, total_cases, total_deaths, CAST(total_deaths AS decimal)/CAST(total_cases AS decimal)*100 as DeathPercntg
FROM PortfolioProject..Cov19_Deaths
WHERE location LIKE '%Kenya%' AND continent IS NOT NULL

SELECT *
FROM DeathPerc_Ke