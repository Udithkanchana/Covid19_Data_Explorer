use Covid_Database

select * 
from CovidDeaths

select *
from CovidVaccinations

--just checking on how the CovidDeaths data behave
select continent,location, date, total_cases, new_cases, total_deaths, new_deaths, population
from CovidDeaths
--where location like '%Sri%'
order by 2,3

--we can get a better understanding of the total cases if we look at them as a percentage of the population.
select location, date, total_cases, population, (total_cases/population)*100 as total_cases_per_pop
from CovidDeaths
where location like '%Sri%'
order by 1,2

--we can get a better understanding of the total deaths if we look at them as a percentage of the population.
select location, date, total_deaths, population,(cast(total_deaths as float)/population)*100 as total_deaths_per_pop
from CovidDeaths
where location like '%Sri%'
order by 1,2

--lets look at the cases vs deaths
select location, date,total_cases, total_deaths,(total_deaths/total_cases)*100 as deaths_per_cases, population
from CovidDeaths
where location like '%Sri%'
order by 1, 2

--countries with highest infection rate compared to population

select location, population, max(total_cases) as max_total_cases,max((total_cases/population)*100) as infection_rate
from CovidDeaths
group by location, population
order by infection_rate desc

--Let's see what are the countries with the highest death count per population

select location, population, max(cast (total_deaths as int)) as max_total_deaths,max((cast (total_deaths as int)/population)*100) as death_rate_per_population
from CovidDeaths
group by location, population
order by death_rate_per_population desc


--but it seems like the location column includes continents as well. That's a problem.
--when the dataset is checked, it's visible that some records have continent name as the location & the continent field is null.
-- we can do a data preproceing, cleansing using python here.
--for now we just try to omit those records to & continue
--lets try the prev query with 'where continent is not null'

select location, continent, population, max(cast (total_deaths as int)) as max_total_deaths,max((cast (total_deaths as int)/population)*100) as death_rate_per_population
from CovidDeaths
where continent is not null
group by location, population, continent
order by death_rate_per_population desc

--Now lets try to do get an idea contient wise
--continents with highest death
select continent, max(cast(total_deaths as int)) as maxdeathcount
from CovidDeaths
where continent is not null
group by continent
order by maxdeathcount desc

--Global numbers

--total deaths, cases iglobally each day 
select date,sum(cast(new_cases as int)) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as deaths_out_of_cases
from CovidDeaths
where continent is not null
group by date
order by 1,2

--gloabal death percentage out of cases (an overall idea)
select sum(cast(new_cases as int)) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as deaths_out_of_cases
from CovidDeaths
where continent is not null
order by 1,2


------Lets explore the vaccination table as well
------will join both the tables & explore

select *
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location=vac.location 
	and dea.date=vac.date
order by dea.location 


--total population vs vaccinations country wise
select dea.continent,dea.location,dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.date) as vaccineRollout
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location=vac.location 
	and dea.date=vac.date
where dea.continent is not null --and dea.location like '%Alb%'
order by 1,2,3

--This demonstrates us how the vccination rollout progress has been each day country wise.
--now lets try to get the vaccination number as a percentage of the population each day to see the progress.
--But we cannot use the new column (vaccineRollout) in the following query to devide it by population.

with popvsVac (Continent,Location, Date, Population, New_Vaccinations, VaccineRollout)
as
(
select dea.continent,dea.location,dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.date) as vaccineRollout
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location=vac.location 
	and dea.date=vac.date
where dea.continent is not null --and dea.location like '%Alb%'
--order by 1,2,3
)
select *, (VaccineRollout/Population)*100 vaccineRolloutPercentage
from popvsVac


--lets create a temporary table with these new data

create table #percentageOfpopulationVaccinated
(
Continent varchar(225),
Location varchar(225), 
Date datetime, 
Population numeric, 
New_Vaccinations numeric, 
VaccineRollout numeric)

insert into #percentageOfpopulationVaccinated
select dea.continent,dea.location,dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.date) as vaccineRollout
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location=vac.location 
	and dea.date=vac.date
--where dea.continent is not null and dea.location like '%Alb%'
--order by 1,2,3

select * 
from #percentageOfpopulationVaccinated


--Lets create a view for later visualizations

create view percentageOfpopulationVaccinated as
select dea.continent,dea.location,dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.date) as vaccineRollout
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location=vac.location 
	and dea.date=vac.date
where dea.continent is not null --and dea.location like '%Alb%'
--order by 1,2,3

