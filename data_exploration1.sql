/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

select * 
from cdeath 
order by 3, 4;


--data that is going to be used

select location, date, total_cases, new_cases, total_deaths, population
from cdeath
order by 1, 3;


--total cases vs total deaths - shows what % of population got covid
--shows the likelihood of dying, if a person gets covid in a particular country

select location, date, total_cases, total_deaths, population,
(total_deaths / total_cases) * 100 as death_percentage
from cdeath
where location = 'India'
order by 1, 3;


--total cases vs population

select location, date, total_cases, population,
(total_cases / population) * 100 as cases_percentage
from cdeath
where location = 'India'
order by 1, 3;


--countries with the highest infection rate as compared to its population

select location, population, max(total_cases) as highest_infection_count, 
max(total_cases / population) * 100 as infection_count_percentage
from cdeath
group by location, population
order by infection_count_percentage desc;


--countries with the highest death count per Population

select location, max(cast(total_deaths as signed)) as highest_deaths
from cdeath
where continent <> ''
group by location
order by highest_deaths desc;


--continents with the highest death count per Population

select location, max(cast(total_deaths as signed)) as highest_deaths
from cdeath
where continent = ''
group by location
order by highest_deaths desc;


--global data of death and cases of each country

select date, sum(total_deaths) as Total_deaths, sum(total_cases) as Total_cases, 
(sum(total_deaths) / sum(total_cases)) * 100 as death_percentage
from cdeath
where continent <> ''
group by date
order by 2 ;


--total population vs vaccinated
--shows percentage of Population that has received at least one Covid Vaccine

select cdeath.continent, cdeath.location, cdeath.date, cdeath.population, covidvaccine.new_vaccinations,
sum(cast(new_vaccinations as signed)) over (partition by cdeath.location order by cdeath.location, cdeath.date)
as rolling_people_vaccinated
from cdeath 
INNER JOIN 
covidvaccine 
ON 
cdeath.location = covidvaccine.location 
and 
cdeath.date = covidvaccine.date
where cdeath.continent <> '' 
order by 2, 3;


-- Using CTE to perform Calculation on Partition By in the previous query

WITH CTE_rollingvaccinations(continent, location, date, population, new_vaccination, rolling_people_vaccinated)
AS
(
select cdeath.continent, cdeath.location, cdeath.date, cdeath.population, covidvaccine.new_vaccinations,
sum(cast(new_vaccinations as signed)) over (partition by cdeath.location order by cdeath.location, cdeath.date)
as 
rolling_people_vaccinated
from cdeath 
INNER JOIN 
covidvaccine 
ON 
cdeath.location = covidvaccine.location 
and 
cdeath.date = covidvaccine.date
where cdeath.continent <> '' 
order by 2, 3
)
SELECT * , (rolling_people_vaccinated / population) * 100 as vaccinated_per_population from CTE_rollingvaccinations;


--Using Temp Table to perform Calculation on Partition By in the previous query

DROP TABLE if exists PercentPopulationVaccinated;

CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
continent text,
location text,
date date,
population int,
new_vaccinations int,
RollingPeopleVaccinated int
);

Insert into PercentPopulationVaccinated
select cdeath.continent, cdeath.location, cdeath.date, cdeath.population, covidvaccine.new_vaccinations,
sum(cast(new_vaccinations as signed)) over (partition by cdeath.location order by cdeath.location, cdeath.date)
as 
rolling_people_vaccinated
from 
cdeath 
INNER JOIN 
covidvaccine 
ON 
cdeath.location = covidvaccine.location 
and 
cdeath.date = covidvaccine.date;

SELECT * , (rolling_people_vaccinated / population) * 100 as vaccinated_per_population from PercentPopulationVaccinated;


-- Creating View to store data

create view global_data as
select date, sum(total_deaths) as Total_deaths, sum(total_cases) as Total_cases, 
(sum(total_deaths) / sum(total_cases)) * 100 as death_percentage
from cdeath
where continent <> ''
group by date
order by 2 ;

select * from global_data;
