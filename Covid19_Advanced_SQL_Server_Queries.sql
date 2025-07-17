
-- Query 1: Top 10 Countries by Death Rate (per 100 Cases)
SELECT TOP 10
    d.location,
    MAX(CAST(d.total_deaths AS FLOAT)) / NULLIF(MAX(CAST(d.total_cases AS FLOAT)), 0) * 100 AS death_rate_percent
FROM 
    CovidDeaths d
WHERE 
    d.continent IS NOT NULL
GROUP BY 
    d.location
ORDER BY 
    death_rate_percent DESC;

-- Query 2: Rolling 7-Day Average of New Cases Using Window Function
SELECT 
    d.location,
    d.date,
    d.new_cases,
    ROUND(AVG(CAST(d.new_cases AS FLOAT)) OVER (
        PARTITION BY d.location 
        ORDER BY CAST(d.date AS DATE)
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_7_day_avg
FROM 
    CovidDeaths d
WHERE 
    d.continent IS NOT NULL;

-- Query 3: Countries with Highest Vaccination per Population
SELECT TOP 10
    d.location,
    MAX(CAST(v.people_vaccinated AS FLOAT)) / NULLIF(MAX(CAST(d.population AS FLOAT)), 0) * 100 AS percent_vaccinated
FROM 
    CovidDeaths d
JOIN 
    CovidVaccinations v 
    ON d.location = v.location AND d.date = v.date
WHERE 
    v.people_vaccinated IS NOT NULL AND d.population IS NOT NULL
GROUP BY 
    d.location
ORDER BY 
    percent_vaccinated DESC;

-- Query 4: CTE: Cases vs Hospital Capacity
WITH CountryMetrics AS (
    SELECT 
        d.location,
        MAX(CAST(d.total_cases AS FLOAT)) AS max_cases,
        MAX(CAST(d.hospital_beds_per_thousand AS FLOAT)) * 1000 AS hospital_capacity_per_million
    FROM 
        CovidDeaths d
    WHERE 
        d.continent IS NOT NULL
    GROUP BY 
        d.location
)
SELECT 
    location,
    max_cases,
    hospital_capacity_per_million,
    ROUND(max_cases / NULLIF(hospital_capacity_per_million, 0), 2) AS stress_factor
FROM 
    CountryMetrics
ORDER BY 
    stress_factor DESC;

-- Query 5: Total Vaccinations vs Total Deaths by Continent
SELECT 
    d.continent,
    SUM(CAST(v.total_vaccinations AS FLOAT)) AS total_vaccinations,
    SUM(CAST(d.total_deaths AS FLOAT)) AS total_deaths,
    ROUND(SUM(CAST(v.total_vaccinations AS FLOAT)) / NULLIF(SUM(CAST(d.total_deaths AS FLOAT)), 0), 2) AS vax_to_death_ratio
FROM 
    CovidDeaths d
JOIN 
    CovidVaccinations v 
    ON d.location = v.location AND d.date = v.date
WHERE 
    d.continent IS NOT NULL
GROUP BY 
    d.continent
ORDER BY 
    vax_to_death_ratio DESC;
