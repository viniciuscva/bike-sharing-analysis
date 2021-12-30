
DROP TABLE IF EXISTS rides
CREATE TABLE rides(
	ride_id VARCHAR(30) primary key,
	rideable_type VARCHAR(30),
	started_at DATETIME,
	ended_at DATETIME,
	ride_length FLOAT,
	day_of_week INT,
	start_station_name VARCHAR(100),
	start_station_id VARCHAR(50),
	end_station_name VARCHAR(100),
	end_station_id VARCHAR(50),
	start_lat DECIMAL(12,8),
	start_lng DECIMAL(12,8),
	end_lat DECIMAL(12,8),
	end_lng DECIMAL(12,8),
	member_casual VARCHAR(30)
);

BULK INSERT rides 
   FROM 'D:\bike_sharing_project\tidy_csv\202012.CSV' WITH
   (
   ROWTERMINATOR = '\n',
   fieldterminator=',',
   FIRSTROW  = 2
   )

BULK INSERT rides 
   FROM 'D:\bike_sharing_project\tidy_csv\202101.CSV' WITH
   (
   ROWTERMINATOR = '\n',
   fieldterminator=',',
   FIRSTROW  = 2
   )

BULK INSERT rides 
   FROM 'D:\bike_sharing_project\tidy_csv\202102.CSV' WITH
   (
   ROWTERMINATOR = '\n',
   fieldterminator=',',
   FIRSTROW  = 2
   )

BULK INSERT rides 
   FROM 'D:\bike_sharing_project\tidy_csv\202103.CSV' WITH
   (
   ROWTERMINATOR = '\n',
   fieldterminator=',',
   FIRSTROW  = 2
   )

BULK INSERT rides 
   FROM 'D:\bike_sharing_project\tidy_csv\202104.CSV' WITH
   (
   ROWTERMINATOR = '\n',
   fieldterminator=',',
   FIRSTROW  = 2
   )

BULK INSERT rides 
   FROM 'D:\bike_sharing_project\tidy_csv\202105.CSV' WITH
   (
   ROWTERMINATOR = '\n',
   fieldterminator=',',
   FIRSTROW  = 2
   )

BULK INSERT rides 
   FROM 'D:\bike_sharing_project\tidy_csv\202106.CSV' WITH
   (
   ROWTERMINATOR = '\n',
   fieldterminator=',',
   FIRSTROW  = 2
   )

BULK INSERT rides 
   FROM 'D:\bike_sharing_project\tidy_csv\202107.CSV' WITH
   (
   ROWTERMINATOR = '\n',
   fieldterminator=',',
   FIRSTROW  = 2
   )

BULK INSERT rides 
   FROM 'D:\bike_sharing_project\tidy_csv\202108.CSV' WITH
   (
   ROWTERMINATOR = '\n',
   fieldterminator=',',
   FIRSTROW  = 2
   )

BULK INSERT rides 
   FROM 'D:\bike_sharing_project\tidy_csv\202109.CSV' WITH
   (
   ROWTERMINATOR = '\n',
   fieldterminator=',',
   FIRSTROW  = 2
   )

BULK INSERT rides 
   FROM 'D:\bike_sharing_project\tidy_csv\202110.CSV' WITH
   (
   ROWTERMINATOR = '\n',
   fieldterminator=',',
   FIRSTROW  = 2
   )

BULK INSERT rides 
   FROM 'D:\bike_sharing_project\tidy_csv\202111.CSV' WITH
   (
   ROWTERMINATOR = '\n',
   fieldterminator=',',
   FIRSTROW  = 2
   )


