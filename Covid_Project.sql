/*
Covid-19 Data Exploration

Skills Used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Use [Covid Project];

Select location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
where continent is not null
order by location, date;

-- Total cases vs Total Deaths (%)
-- Likelihood of Death if you contract covid-19 in India

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage  
From CovidDeaths
where location = 'India' and continent is not null
order by location, date;


-- Total Cases vs population
-- Shows what percent of population infected with covid-19

Select location, date, total_cases, population, (total_cases/population)*100 as CasePercentage  
From CovidDeaths
where location = 'India' and continent is not null
order by location, date desc;


-- Countries with Highest Infection Rate per Population

Select location, population, Max(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as HighestInfectionRate  
From CovidDeaths
where continent is not null
Group by location, population
order by HighestInfectionRate desc;


-- Countries with Highest Death Count per Population

Select location, Max(cast(total_deaths as int)) as TotalDeathCount
From CovidDeaths
where continent is not null
Group by location
order by TotalDeathCount desc;


-- Countries with Highest Death Count by Continent 

Select continent, Max(cast(total_deaths as int)) as TotalDeathCount
From CovidDeaths
where continent is not null
Group by continent
order by TotalDeathCount desc;


-- Global Numbers

-- By Date
Select 
	date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as Total, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From CovidDeaths
where continent is not null
Group by date
order by date;


-- Total Global Numbers
Select 
	SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as Total, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From CovidDeaths
where continent is not null;


-- Tables CovidDeath and CovidVaccination Joined

Select d.*, v.*
From
	CovidDeaths d
	Join
CovidVaccinations v on d.location = v.location
	and d.date = v.date;


-- Total Population vs Vaccination
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(bigint, v.new_vaccinations)) OVER (partition by d.location Order by d.location, d.date) as RollingPeopleVaccinated
From
	CovidDeaths d
	Join
CovidVaccinations v on d.location = v.location
	and d.date = v.date
where d.continent is not null
order by d.location, d.date;


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(bigint, v.new_vaccinations)) OVER (partition by d.location Order by d.location, d.date) as RollingPeopleVaccinated
From
	CovidDeaths d
	Join
CovidVaccinations v on d.location = v.location
	and d.date = v.date
where d.continent is not null
-- order by d.continent, d.location, d.date;
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac;


-- Using Temp Table to perform Calculation on Partition By in previous query

Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(bigint, v.new_vaccinations)) OVER (partition by d.location Order by d.location, d.date) as RollingPeopleVaccinated
From
	CovidDeaths d
	Join
CovidVaccinations v on d.location = v.location
	and d.date = v.date
-- where d.continent is not null
-- order by d.continent, d.location, d.date;

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(bigint, v.new_vaccinations)) OVER (partition by d.location Order by d.location, d.date) as RollingPeopleVaccinated
From
	CovidDeaths d
	Join
CovidVaccinations v on d.location = v.location
	and d.date = v.date
where d.continent is not null;

Select *
From PercentPopulationVaccinated;

