This first project aimed to develop my SQL skills using MS SQL Server and coral data collected in Malaysia in 2019/2020 by Szereday et al., 2024 <a href="https://doi.org/10.1007/s00227-024-04495-2" >(click me)</a>, investigating the effects of back-to-back thermal stress events on coral health (i.e., bleaching response).

The dataset includes 3755 rows with following columns:
Year,
Wind,
Depth,
Habitat,
Site,
Genus,
Form,
Bleaching Score,
Bleaching_Binary,
Depth_Binary,
Wind_Binary,
max_DHW,
Depth (m),
Morphotaxa,
avg_DHW,
SS_DHW,
CRW_DHW.

Here I focused on the parameters interesting to me: Year, Depth (m), Site, (Genus, Form), Morphotaxa (concat(GenusForm)), Bleaching Score.
Year FLOAT,
Depth (m) FLOAT,
Site nvarchar(255),
Morphotaxa nvarchar(255),
Bleaching Score FLOAT.
The higher the Bleaching Score, the higher the loss of pigmentation, the lower the coral health is.

I divided the project into several pieces, each answering one scientific question while training basic-intermediate SQL skills.


Let's explore the data provided, first checking if there is a differnce in the average bleaching score across depths (6 and 12 m)
```SQL
SELECT DISTINCT
	[Depth (m)],
	ROUND(AVG([Bleaching Score]) OVER (PARTITION BY [Depth (m)]),1) AS [AVG_Bleaching_Score]
  FROM [SQL_Project].[dbo].['All Data$']
 WHERE [Bleaching Score] IS NOT NULL
 ORDER BY [Depth (m)] ASC;
```
There is a difference, but it seems to be marginally. We can include more parameters, such as year, site and morphotaxa to find putative differences. 
Let's break it down to Year and Genus first.
```SQL
SELECT DISTINCT 
	[Year],	
	[Genus],
	ROUND(AVG([Bleaching Score]) OVER (PARTITION BY [Genus], [Year]),1) AS AVG_Bleaching_Score
FROM [SQL_Project].[dbo].['All Data$']
ORDER BY [AVG_Bleaching_Score] DESC;
```
Here, I selected the top 20 entries in a `DISTINCT` format using more variables for a more complete review of the data.
```SQL
 --Account for parameters--
SELECT DISTINCT TOP 20
	[Year],	
	[Site],
	[Depth (m)],
	[Morphotaxa],
	ROUND(AVG([Bleaching Score]) OVER (PARTITION BY [Depth (m)], [Year], [Site], [Morphotaxa]), 1) AS [AVG_Bleaching_Score]
FROM [SQL_Project].[dbo].['All Data$']
WHERE Year IS NOT NULL
ORDER BY [AVG_Bleaching_Score] DESC;
```
To find and export putative differences between the years in bleaching scores for every morphotxa, we first need to create a table for insert the extracted data into. The subsquent CTEs are needed to compare the entries that are present in both years and to compare these exact matches. 
```SQL
--The data from 2019 (1882 rows) and 2020 (1873 rows) IS NOT same sized. As I want to compare the same genus / morphotaxa entry across year, a continuous ID within Morphotaxa can help, using the row_number() function within a CTE for each year.--
--Create a table where to store the output in.--
CREATE TABLE [Bleaching Score Difference] (
		[Site] VARCHAR(50),
		[Depth (m)] INTEGER,
		[Morphotaxa] VARCHAR(50),
		[Bleaching Score 2019] INTEGER,
		[Bleaching Score 2020] INTEGER,
		[Bleaching Score difference between 2019 and 2020] INTEGER
		)

--simplify the approach of separate columns for the bleaching scores given in year 2019 and 2020 as well as assigned IDs to compare the same IDs within parameters with one another.--
WITH Data_2019_Ranked AS (
    SELECT 	
		[Site],
		[Depth (m)],
		[Morphotaxa],
		[Bleaching Score] AS [Bleaching Score 2019],
           ROW_NUMBER() OVER (
               PARTITION BY [Morphotaxa], [Site], [Depth (m)]
               ORDER BY [Bleaching Score] ASC
           ) AS ID
    FROM [SQL_Project].[dbo].['All Data$']
	WHERE [Year] = 2019
),
Data_2020_Ranked AS (
    SELECT 
		[Site],
		[Depth (m)],
		[Morphotaxa],
		[Bleaching Score] AS [Bleaching Score 2020],
           ROW_NUMBER() OVER (
               PARTITION BY [Morphotaxa], [Site], [Depth (m)] 
               ORDER BY [Bleaching Score] ASC
           ) AS ID
    FROM [SQL_Project].[dbo].['All Data$']
	WHERE [Year] = 2020
)
--insert the output in the created table.--
INSERT INTO  [SQL_Project].[dbo].[Bleaching Score Difference] (
		[Site],
		[Depth (m)],
		[Morphotaxa],
		[Bleaching Score 2019],
		[Bleaching Score 2020],
		[Bleaching Score difference between 2019 and 2020]
		)
--use aliases to clean up the data a bit and avoid duplicate columns (e.g., Form 2019, Form 2020).--
SELECT 
    d19.[Site], 
    d19.[Depth (m)], 
    d19.[Morphotaxa],
    d19.[Bleaching Score 2019], 
    d20.[Bleaching Score 2020],
    (d19.[Bleaching Score 2019] - d20.[Bleaching Score 2020]) AS [Bleaching Score difference between 2019 and 2020]
FROM Data_2019_Ranked d19
JOIN Data_2020_Ranked d20
ON d19.[Morphotaxa] = d20.[Morphotaxa]
AND d19.[Depth (m)] = d20.[Depth (m)]
AND d19.[Site]=d20.[Site]
AND d19.ID = d20.ID -- Ensures correct pairing of replicates
ORDER BY [Bleaching Score difference between 2019 and 2020] ASC, 
         d19.[Site], d19.[Depth (m)], d19.[Morphotaxa];

--select top 20 distinct morphotaxa with the highest decline in health between 2019 and 2020.--
SELECT DISTINCT TOP 20*
FROM [SQL_Project].[dbo].[Bleaching Score Difference]
ORDER BY [Bleaching Score difference between 2019 and 2020] ASC;
```
