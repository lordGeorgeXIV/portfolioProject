--Proyecto Covid 19

-- seleccionamos los datos que vamos a estar utilizando
select *
from portfolioProject..CovidDeaths;

select location, date, total_cases, new_cases, total_deaths, population 
from portfolioProject..CovidDeaths
order by 1,2;

-- 1. looking at total cases vs totals deaths in united states 
select location, date,total_cases, total_deaths, round((total_deaths/total_cases)*100, 2) as deathPercantage
from portfolioProject..CovidDeaths
where location like '%states%'
order by deathPercantage asc;

-- 2. looking at population vs total cases  in united states 
select location, date,total_cases, total_deaths, round((total_cases/population)*100, 2) as percentPopulation
from portfolioProject..CovidDeaths
where location like '%states%'and total_deaths is not null
order by percentPopulation;

-- 3. looking at countries with highest infection rates compared to population
select location,population, max(total_cases) max_cases, round(max((total_cases/population))*100, 2) max_population_perc
from portfolioProject..CovidDeaths
group by location, population
order by max_population_perc desc;


-- 3. looking at countries with highest death count per population
select location,population, max(cast(total_deaths as int)) total_death_count
from portfolioProject..CovidDeaths
where continent is not null
group by location, population
order by total_death_count desc;	

-- 4. break things down by continent
select continent, max(cast(total_deaths as int)) total_deaths
from portfolioProject..CovidDeaths
where continent is not null
group by continent
order by total_deaths desc;

-- la informacion no se ve exacta, probemos con location
select location, max(cast(total_deaths as int)) total_deaths
from portfolioProject..CovidDeaths
where continent is null
group by location
order by total_deaths desc;

--global numbers 
-- numero de casos por fecha
select date, sum(new_cases) total_cases, 
sum(cast(new_deaths as int)) total_deaths, 
round((sum(cast(new_deaths as int))/sum(new_cases))*100, 2) death_percentage
from portfolioProject..CovidDeaths
where continent is not null
group by date
order by 1;

-- join covid deaths and covid vaccinations
-- verificamos las columnas en comun
select * 
from portfolioProject..CovidDeaths;

select * 
from portfolioProject..CovidVaccinations;

-- looking at total population vs. vaccinations, suma de vacunas particionado por locacion y fecha, porcentage de vacunacion por poblacion por fecha sin cte's
select 

	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	sum(cast(new_vaccinations as int))over(partition by dea.location order by dea.location, dea.date) sum_vac_by_loc_dat,
	round((sum(cast(new_vaccinations as int))over(partition by dea.location order by dea.location, dea.date)/dea.population)*100,3) perc_sum_vac_pop -- forma de ejecutar esta operacion

from portfolioProject..CovidDeaths dea
join portfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	and vac.new_vaccinations is not null
	order by 2,3;

-- CTE'S --
-- looking at total population vs. vaccinations, suma de vacunas particionado por locacion y fecha, porcentage de vacunacion por poblacion por fecha con cte's
with popVsVac (continent, location, date, population, new_vaccinations, sum_vac_by_loc_dat)
as(
	select 

		dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		sum(cast(new_vaccinations as int))over(partition by dea.location order by dea.location, dea.date) sum_vac_by_loc_dat
		--(sum_vac_by_loc_dat/population)*100 perc_sum_vac_pop --no se puede

	from portfolioProject..CovidDeaths dea
	join portfolioProject..CovidVaccinations vac
		on dea.location = vac.location
		and dea.date = vac.date
		where dea.continent is not null
		and vac.new_vaccinations is not null
		--order by 2,3 -- no se puede usar el order by cuando creamos cte's
	)

	select date, population, location, sum_vac_by_loc_dat,round((sum_vac_by_loc_dat/population)*100,4)
	from popVsVac
	order by 5 desc
	--group by date, location

	

-- TEMP TABLES --
-- looking at total population vs. vaccinations, suma de vacunas particionado por locacion y fecha, porcentage de vacunacion por poblacion por fecha con TEMP TABLES

drop table if exists porcentage_poblacion_vacunada
create table porcentage_poblacion_vacunada
(
		continent varchar(255), 
		location varchar(255), 
		date datetime, 
		population numeric, 
		new_vaccinations numeric,
		sum_vac_by_loc_dat numeric
)
insert into porcentage_poblacion_vacunada
select 

		dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		sum(cast(new_vaccinations as int))over(partition by dea.location order by dea.location, dea.date) sum_vac_by_loc_dat

	from portfolioProject..CovidDeaths dea
	join portfolioProject..CovidVaccinations vac
		on dea.location = vac.location
		and dea.date = vac.date
		where dea.continent is not null
		and vac.new_vaccinations is not null;

-- creating view to store data for later visualizations

create view view_porcentaje_poblacion_vacunada
	as 
	select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	sum(cast(new_vaccinations as int))over(partition by dea.location order by dea.location, dea.date) sum_vac_by_loc_dat,
	round((sum(cast(new_vaccinations as int))over(partition by dea.location order by dea.location, dea.date)/dea.population)*100,3) perc_sum_vac_pop -- forma de ejecutar esta operacion

from portfolioProject..CovidDeaths dea
join portfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	and vac.new_vaccinations is not null
	--order by 2,3;

	select * 
	from view_porcentaje_poblacion_vacunada
	order by 2,3;