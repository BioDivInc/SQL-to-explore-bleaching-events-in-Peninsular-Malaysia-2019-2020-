/*1) Is there a difference in bleaching scores depending on water depth (i.e., 6 m vs. 12 m sampled corals)? 
Investigates the general notion of a difference in bleaching depending on water depth alone.*/
SELECT DISTINCT --select only distinct values as we only need the average for two depths and not all entries.--
	[Depth (m)],
	ROUND(AVG([Bleaching Score]) OVER (PARTITION BY [Depth (m)]),1) AS [AVG_Bleaching_Score] --add round() function to round the output to one decimal place.--
FROM [SQL_Project].[dbo].['All Data$']
WHERE [Depth (m)] IS NOT NULL
ORDER BY [Depth (m)] ASC;
--There is only a marginal difference between the average bleaching scores at 6 and 12 meters water depth. The averaging function does not account for Year, Site, Morphotaxa. To investigate a possible difference between Genus and Form (i.e., Morphotaxa), an adjustment is in order.



/*2) Is there a difference between genera or rather [Morphotaxa]?
Site, Year, (Genus, Form) Morphotaxa might make a difference that can be accounted for by adjusting the arguments within the 'partition by' clause. As the output would be 633 rows, I reduced the output to the top 20 worst performers.*/
SELECT DISTINCT TOP 20 --select only for the top 20 entries, ordered by the average bleaching score based on following parameters in descending order.--
	[Year],	
	[Site],
	[Depth (m)],
	[Morphotaxa],
	ROUND(AVG([Bleaching Score]) OVER (PARTITION BY [Depth (m)], [Year], [Site], [Morphotaxa]), 1) AS [AVG_Bleaching_Score] --add round() function to round the output to one decimal place, as more do not add any further value to the bleaching score.--
FROM [SQL_Project].[dbo].['All Data$']
ORDER BY [AVG_Bleaching_Score] DESC;
--What are the top 20 best performers then? That can be displayed simply by changing the last line of code to: ORDER BY [AVG_Bleaching_Score] ASC;--

SELECT DISTINCT TOP 20 --select only for the top 20 entries, ordered by the average bleaching score based on following parameters in descending order.--
	[Year],	
	[Site],
	[Depth (m)],
	[Morphotaxa],
	ROUND(AVG([Bleaching Score]) OVER (PARTITION BY [Depth (m)], [Year], [Site], [Morphotaxa]), 1) AS [AVG_Bleaching_Score] --add round() function to round the output to one decimal place, as more do not add any further value to the bleaching score.--
FROM [SQL_Project].[dbo].['All Data$']
WHERE [Year] IS NOT NULL
ORDER BY [AVG_Bleaching_Score] ASC;

--But what are the most and least susceptible genera? The tables above include not only the site and depth but also the form, which makes it harder to read, when only interested in the performance of each [Genus] per year.--
SELECT DISTINCT 
	[Year],	
	[Genus],
	ROUND(AVG([Bleaching Score]) OVER (PARTITION BY [Genus], [Year]),1) AS AVG_Bleaching_Score
FROM [SQL_Project].[dbo].['All Data$']
WHERE [Year] IS NOT NULL
ORDER BY [AVG_Bleaching_Score] DESC;




/*3)Is there a difference between Year 2019 and Year 2020? If so, which [Morphotaxa] displayed the highest difference between the back-to-back bleaching events? Here, a negative value represents a decline in coral health from Year 2019 to 2020.*/
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