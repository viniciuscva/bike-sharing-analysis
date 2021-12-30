SELECT TOP 5 * FROM cyclistic_db.dbo.rides;

-- Perguntas para serem respondidas na análise:


-- limitações: qual o período de tempo estudado?
SELECT 
	MIN(started_at) AS oldest_date,
	MAX(started_at) AS latest_date
FROM
	rides
	



-- Quantos passeios houveram nos últimos 12 meses? 
SELECT COUNT(*) AS total_rides FROM rides; -- 5.479.096 rows




-- Quantos passeios houveram em cada um dos últimos 12 meses?
SELECT 
	CONCAT(MONTH(started_at),'/',YEAR(started_at)) AS month,
	COUNT(*) AS total_rides
FROM 
	rides
GROUP BY YEAR(started_at), MONTH(started_at)
ORDER BY YEAR(started_at), MONTH(started_at);



-- Quantos passeios foram de casuais e quantos foram de membros?
SELECT
	member_casual,
	COUNT(*) AS total_rides
FROM
	rides
GROUP BY member_casual




-- comparar passeios de casuais vs passeios de membros mês a mês
-- usarei SUM(CASE WHEN) como se fosse um COUNTIF !
SELECT 
	CONCAT(MONTH(started_at),'/',YEAR(started_at)) AS month,
	SUM(CASE WHEN member_casual = 'casual' THEN 1 ELSE 0 END) AS casual_rides,
	SUM(CASE WHEN member_casual = 'member' THEN 1 ELSE 0 END) AS member_rides
FROM rides
GROUP BY MONTH(started_at), YEAR(started_at)
ORDER BY YEAR(started_at), MONTH(started_at)



-- contagem de uso dos tipos de bicicletas pelos membros? E pelos casuais? 
SELECT member_casual, rideable_type, COUNT(*) AS total_rides
FROM rides
GROUP BY member_casual,rideable_type
ORDER BY member_casual, rideable_type;



-- O tipo de bicicleta mais usado pelos membros? e pelos casuais?
WITH client_vs_bike AS
	(SELECT member_casual, rideable_type, COUNT(*) AS total_rides
	 FROM rides
	 GROUP BY member_casual,rideable_type)
SELECT * 
FROM client_vs_bike
WHERE 
	(member_casual = 'casual' AND total_rides = (SELECT MAX(total_rides) 
												 FROM client_vs_bike
												 WHERE member_casual = 'casual'))
	OR
	(member_casual = 'member' AND total_rides = (SELECT MAX(total_rides)
												 FROM client_vs_bike 
												 WHERE member_casual = 'member'))
;


-- O tipo mais usado pelos membros e pelos casuais analizando mês a mês
WITH month_client_bike AS
	(SELECT YEAR(started_at) AS year,
			MONTH(started_at) AS month,
			member_casual AS client_type,
			rideable_type AS bike_type,
			COUNT(*) AS total_rides
	 FROM rides
	 GROUP BY YEAR(started_at),MONTH(started_at), member_casual, rideable_type),
month_client AS
	(SELECT 
		year,
		month, 
		client_type,
		SUM(CASE WHEN bike_type = 'classic_bike' THEN total_rides ELSE 0 END) AS classic_bike_rides,
		SUM(CASE WHEN bike_type = 'electric_bike' THEN total_rides ELSE 0 END) AS electric_bike_rides,
		SUM(CASE WHEN bike_type = 'docked_bike' THEN total_rides ELSE 0 END) AS docked_bike_rides
	 FROM month_client_bike 
	 GROUP BY year,month, client_type)
SELECT 
	CONCAT(year,'-',month) AS year_month,
	client_type,
	classic_bike_rides,
	electric_bike_rides,
	docked_bike_rides
FROM month_client
ORDER BY year, month, client_type




-- Outra forma para analisar o tipo de bicicleta mais usado pelos membros e pelos casuais analizando mês a mês
WITH monthly_totals AS
	(SELECT 
		CONCAT(YEAR(started_at), '-',MONTH(started_at)) AS month, 
		member_casual,
		COUNT(*) AS total_rides
	 FROM rides
	 GROUP BY YEAR(started_at), MONTH(started_at), member_casual),
bike_type_grouping AS
	(SELECT 
		CONCAT(YEAR(started_at),'-',MONTH(started_at)) AS month,
		member_casual,
		rideable_type,
		COUNT(*) AS total_rides
	FROM rides
	GROUP BY YEAR(started_at), MONTH(started_at), member_casual, rideable_type)
SELECT 
	b.month,
	b.member_casual,
	b.rideable_type,
	b.total_rides AS total_rides_for_bike_and_client_type,
	m.total_rides AS monthly_total_rides_for_client_type,
	100.0*b.total_rides/m.total_rides AS perc_for_bike_type
FROM 
	monthly_totals m
	INNER JOIN
	bike_type_grouping b
	ON
	m.month = b.month 
	AND
	m.member_casual = b.member_casual
ORDER BY b.month, b.member_casual, b.rideable_type




-- Quem aluga por mais tempo em média: casuais ou membros? e por mês?
SELECT member_casual, AVG(ride_length) AS avg_mins_ride_length
FROM rides
GROUP BY member_casual




-- quem aluga por mais tempo analisando mês a mês
SELECT 
	CONCAT(YEAR(started_at),'-',MONTH(started_at)) AS month,
	member_casual, 
	AVG(ride_length) AS avg_mins_ride_length_month
FROM rides
GROUP BY YEAR(started_at),MONTH(started_at),member_casual
ORDER BY YEAR(started_at),MONTH(started_at),member_casual;



-- Quem percorre distâncias maiores em média: casuais ou membros?
-- Prepare-se! Precisamos de uma fórmula para calcular a distância entre o ponto inicial do passeio e o ponto final, em latitudes e longitudes
-- Abaixo segue um código capaz de fazer este cálculo e que foi editado de um retirado da página
-- https://www.dirceuresende.com/blog/sql-server-como-calcular-a-distancia-entre-dois-locais-utilizando-latitude-e-longitude-sem-api/ 

DROP FUNCTION IF EXISTS dbo.fncCalcula_Distancia_Coordenada
CREATE FUNCTION dbo.fncCalcula_Distancia_Coordenada (
    @Latitude1 FLOAT,
    @Longitude1 FLOAT,
    @Latitude2 FLOAT,
    @Longitude2 FLOAT
) RETURNS FLOAT
AS
BEGIN
 
    DECLARE @PI FLOAT = PI()
 
    DECLARE @lat1Radianos FLOAT = @Latitude1 * @PI / 180
    DECLARE @lng1Radianos FLOAT = @Longitude1 * @PI / 180
    DECLARE @lat2Radianos FLOAT = @Latitude2 * @PI / 180
    DECLARE @lng2Radianos FLOAT = @Longitude2 * @PI / 180

	DECLARE @x FLOAT = COS(@lat1Radianos) * COS(@lng1Radianos) * COS(@lat2Radianos) * COS(@lng2Radianos) + 
		COS(@lat1Radianos) * SIN(@lng1Radianos) * COS(@lat2Radianos) * SIN(@lng2Radianos) + SIN(@lat1Radianos) * SIN(@lat2Radianos)
	IF  (@x > 1.0)
         SET @x = 1
    ELSE IF (@x < -1.0)
         SET @x = -1

    RETURN (ACOS(@x) * 6371) * 1.15
END
;

-- criando uma tabela temporária que guarda as distâncias dos percursos
-- há algumas linhas onde alguns dos valores de latitude e longitude são NULLs, assim nesses casos,
-- nesta query temporária defini a distância do percurso como -1
-- na linha 718 e em outras linhas da tabela tinha ocorrido um erro no cálculo da distância
-- devido a aproximação de cálculos com FLOAT 
-- ter gerado um argumento fora do intervalo [-1,1] para a função ACOS, o que não é permitido.
-- Assim concertei a função dbo.fncCalcula_Distancia_Coordenada para o ACOS não receber valores fora do intervalo [-1,1].
-- OBS: A query abaixo leva em média 5min para executar
WITH tb AS
	(SELECT *, 
		CASE WHEN (start_lat IS NULL OR start_lng IS NULL OR end_lat IS NULL OR end_lng IS NULL) THEN -1
		ELSE dbo.fncCalcula_Distancia_Coordenada(start_lat,start_lng,end_lat,end_lng) END AS dist_km
	 FROM rides)
SELECT member_casual, AVG(dist_km) as avg_distance_km
FROM tb
WHERE dist_km <> -1
GROUP BY member_casual;




-- Então acho melhor dá logo um ALTER TABLE, adicionando a coluna distance_km para que esta computação nunca mais precise ser feita
ALTER TABLE rides ADD distance_km FLOAT;
UPDATE rides SET distance_km = NULL WHERE start_lat IS NULL OR 
		start_lng IS NULL OR end_lat IS NULL OR end_lng IS NULL;

UPDATE rides SET distance_km = dbo.fncCalcula_Distancia_Coordenada(start_lat,start_lng,end_lat,end_lng) WHERE start_lat IS NOT NULL AND 
		start_lng IS NOT NULL AND end_lat IS NOT NULL AND end_lng IS NOT NULL;



-- nova query, muito mais rápida, levando em média apenas 4 segundos para executar
SELECT
	member_casual, 
	AVG(distance_km) as avg_distance_km
FROM rides
WHERE distance_km IS NOT NULL
GROUP BY member_casual;




-- agora mês a mês
SELECT
	CONCAT(MONTH(started_at),'/',YEAR(started_at)) AS month,
	member_casual, 
	AVG(distance_km) as avg_distance_km
FROM rides
WHERE distance_km IS NOT NULL
GROUP BY year(started_at), month(started_at), member_casual
ORDER BY year(started_at), month(started_at), member_casual;




-- como descobrir quais estações possuem inconsistência em relação ao par start_station_name, start_station_id
WITH distinct_pairs AS
	(SELECT DISTINCT start_station_name, start_station_id
	 FROM rides),
counting_names AS
	(SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY start_station_name ORDER BY start_station_name,start_station_id ) AS count
	FROM
		distinct_pairs),
repeating_names AS
	(SELECT DISTINCT start_station_name
	 FROM counting_names
	 WHERE count > 1)
,tb AS
	((SELECT *
	FROM distinct_pairs
	WHERE  start_station_name IN (SELECT * FROM repeating_names)) 
	UNION
	(SELECT *
	FROM distinct_pairs
	WHERE start_station_name IS NULL)  )
SELECT * FROM tb
-- That's because unfortunatelly to SQL Server, [NULL IN (NULL)] IS FALSE!


-- ===============================================================
-- OBS: A query abaixo é praticamente idêntica a anterior, porém por algum motivo desconhecido
-- ela aparentemente nunca termina, esperei mais de 6 minutos e não completo, já a query anterior
-- custou menos de 30 segundos
WITH distinct_pairs2 AS
	(SELECT DISTINCT start_station_name, start_station_id
	 FROM rides),
counting_names AS
	(SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY start_station_name ORDER BY start_station_name,start_station_id ) AS count
	FROM
		distinct_pairs2),
repeating_names AS
	(SELECT DISTINCT start_station_name
	 FROM counting_names
	 WHERE count > 1)
SELECT *
	FROM distinct_pairs2
	WHERE  (start_station_name IN (SELECT * FROM repeating_names)) OR (start_station_name IS NULL)

-- ================================================================



-- ou
SELECT DISTINCT start_station_name, start_station_id
FROM rides
ORDER BY start_station_id, start_station_name


-- ou
with tb as
	(SELECT DISTINCT start_station_name, start_station_id
	FROM rides)
select 
	start_station_name,
	start_station_id,
	ROW_NUMBER() OVER (PARTITION BY start_station_id ORDER BY start_station_id ) AS count
from tb
order by start_station_id, count


-- outra forma
with tb as
	(SELECT distinct start_station_name, start_station_id 
	from rides )
select coalesce(start_station_name,start_station_id), count(*)
from tb
group by coalesce(start_station_name,start_station_id)
order by count(*) desc

SELECT distinct start_station_name, start_station_id FROM rides WHERE start_station_name LIKE 'Loomis St%' OR start_station_id LIKE 'Loomis St%'




-- Quais as estações a partir das quais mais saem bicicletas? 
SELECT
	COALESCE(start_station_name, start_station_id) AS start_station, 
	COUNT(*) AS total_rides_starting_from
FROM rides
WHERE start_station_name IS NOT NULL OR start_station_id IS NOT NULL
GROUP BY COALESCE(start_station_name, start_station_id)
ORDER BY total_rides_starting_from DESC




-- Quais as estações nas quais mais chegam bicicletas?
SELECT
	COALESCE(end_station_name, end_station_id) AS end_station, 
	COUNT(*) AS total_rides_ending_at
FROM rides
WHERE end_station_name IS NOT NULL OR end_station_id IS NOT NULL
GROUP BY COALESCE(end_station_name, end_station_id)
ORDER BY total_rides_ending_at DESC




-- Quais as estações preferidas dos casuais? E dos membros?
SELECT TOP 10
	COALESCE(start_station_name, start_station_id) AS start_station,
	member_casual,
	COUNT(*) as total_rides
FROM
	rides
GROUP BY COALESCE(start_station_name, start_station_id), member_casual
HAVING COALESCE(start_station_name, start_station_id) IS NOT NULL
ORDER BY COUNT(*) DESC




-- Quais os dias da semana nos quais mais ocorre aluguéis?
SELECT 
	DATENAME(WEEKDAY, started_at) AS weekday,
	COUNT(*) AS total_rides
FROM
	rides
GROUP BY DATENAME(WEEKDAY, started_at)
ORDER BY COUNT(*) DESC




-- Quais os dias da semana nos quais mais terminam aluguéis?
SELECT 
	DATENAME(WEEKDAY, ended_at) AS weekday,
	COUNT(*) AS total_rides
FROM
	rides
GROUP BY DATENAME(WEEKDAY, ended_at)
ORDER BY COUNT(*) DESC




-- Quais os dias da semana preferidos pelos casuais? E pelos membros?
SELECT TOP 10
	DATENAME(WEEKDAY, started_at) AS weekday,
	member_casual,
	COUNT(*) AS total_rides
FROM
	rides
GROUP BY DATENAME(WEEKDAY, started_at), member_casual
ORDER BY total_rides DESC




SELECT TOP 10
	DATENAME(WEEKDAY, ended_at) AS weekday,
	member_casual,
	COUNT(*) AS total_rides
FROM
	rides
GROUP BY DATENAME(WEEKDAY, ended_at), member_casual
ORDER BY total_rides DESC



-- Number 1 favorite weekday by client type
WITH favorite_weekdays AS
	(SELECT 
		DATENAME(WEEKDAY, started_at) AS weekday,
		member_casual,
		COUNT(*) AS total_rides
	 FROM
		rides
	 GROUP BY DATENAME(WEEKDAY, started_at), member_casual),
best_weekday_for_members AS 
	(SELECT *
	 FROM favorite_weekdays
	 WHERE member_casual = 'member' AND total_rides = (SELECT MAX(total_rides)  
	 												   FROM favorite_weekdays 
													   WHERE member_casual = 'member')
	 ),
best_weekday_for_casuals AS 
	(SELECT *
	 FROM favorite_weekdays
	 WHERE member_casual = 'casual' AND total_rides = (SELECT MAX(total_rides)  
													   FROM favorite_weekdays 
													   WHERE member_casual = 'casual')
	 ),
best_weekday AS
	((SELECT * FROM best_weekday_for_members) UNION (SELECT * FROM best_weekday_for_casuals))
SELECT * FROM best_weekday
