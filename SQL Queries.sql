---Q1: How many vehicles have been stolen in total?

SELECT
	COUNT(*) AS TOTAL_STOLEN_VEHICLES
FROM STOLEN_VEHICLES
	
---Q2: What are the most common vehicle types stolen?

SELECT
	VEHICLE_TYPE
	COUNT(*)
FROM STOLEN_VEHICLES
GROUP BY VEHICLE_TYPE
ORDER BY 2 DESC


---Q3: Which year had the highest number of stolen vehicles?

SELECT
	EXTRACT(YEAR FROM DATE_STOLEN),
	COUNT(*)
FROM STOLEN_VEHICLES
GROUP BY 1
ORDER BY 2 DESC


---Q4: What are the top 5 most stolen vehicle makes?

SELECT M.MAKE_NAME, COUNT(V.VEHICLE_ID) AS COUNT
FROM STOLEN_VEHICLES V
JOIN MAKE_DETAILS M ON V.MAKE_ID = M.MAKE_ID
GROUP BY M.MAKE_NAME
ORDER BY COUNT DESC
LIMIT 5;

---Q5: Which locations (region) report the highest number of vehicle thefts?

SELECT L.REGION, COUNT(V.VEHICLE_ID)
FROM LOCATIONS AS L
JOIN STOLEN_VEHICLES AS V ON L.LOCATION_ID = V.LOCATION_ID
GROUP BY L.REGION
ORDER BY 2 DESC

---Q6: What is the distribution of vehicle theft incidents across different population density 

SELECT
    CASE
        WHEN L.DENSITY < 100 THEN 'Low'
        WHEN L.DENSITY BETWEEN 100 AND 150 THEN 'Medium'
        ELSE 'High'
    END AS Density_Category,
    COUNT(V.VEHICLE_ID) AS Theft_Count
FROM
    LOCATIONS AS L
JOIN
    STOLEN_VEHICLES AS V ON L.LOCATION_ID = V.LOCATION_ID
GROUP BY
    Density_Category
ORDER BY
    Theft_Count DESC;

---Q7: Are newer or older vehicles more likely to be stolen?

SELECT 
    CASE 
        WHEN MODEL_YEAR >= (SELECT AVG(MODEL_YEAR) FROM STOLEN_VEHICLES) THEN 'Newer' 
        ELSE 'Older' 
    END AS Vehicle_Age, 
    COUNT(VEHICLE_ID) AS COUNT
FROM 
    STOLEN_VEHICLES
GROUP BY 
    Vehicle_Age
ORDER BY 
    COUNT DESC;


---Q8: Which vehicle types are stolen the most in urban vs. rural areas (based on population density)?

SELECT
   V.VEHICLE_TYPE,
	CASE 
		WHEN L.DENSITY<= 200 THEN 'Urban'
		ELSE 'Rural'
		END AS DENSITY_GROUP,
	COUNT(V.VEHICLE_ID) AS THEFT_COUNT
FROM STOLEN_VEHICLES AS V
JOIN LOCATIONS AS L ON V.LOCATION_ID = L.LOCATION_ID
GROUP BY 1, 2
ORDER BY 2, 3 DESC



---Q9: Find the percentage of stolen vehicles for each make type

SELECT
	MD.MAKE_TYPE,
	COUNT(V.VEHICLE_ID) AS STOLEN_COUNT,
	ROUND(
		(
			COUNT(V.VEHICLE_ID) * 100.0 / (
				SELECT
					COUNT(*)
				FROM
					STOLEN_VEHICLES
			)
		),
		2
	) AS PERCENTAGE_STOLEN
FROM MAKE_DETAILS AS MD
	JOIN STOLEN_VEHICLES AS V ON MD.MAKE_ID = V.MAKE_ID
GROUP BY MD.MAKE_TYPE
ORDER BY PERCENTAGE_STOLEN DESC

---Q10:  Find the region where vehicle thefts increased the most between two consecutive years 

WITH YEARLY_THEFT AS(
		SELECT L.REGION, EXTRACT (YEAR FROM DATE_STOLEN) AS THEFT_YEAR, COUNT(V.VEHICLE_ID) AS TOTAL_STOLEN
		FROM STOLEN_VEHICLES AS V
		JOIN LOCATIONS AS L ON V.LOCATION_ID = L.LOCATION_ID
		GROUP BY 1, 2
)
SELECT A.REGION, A.THEFT_YEAR, (A.TOTAL_STOLEN-B.TOTAL_STOLEN) AS INCREASE_IN_THEFTS
FROM YEARLY_THEFT AS A
JOIN YEARLY_THEFT AS B ON A.REGION = B.REGION AND A.THEFT_YEAR = B.THEFT_YEAR +1
ORDER BY 3 DESC
LIMIT 1

---Q11: Find the most common vehicle make stolen in each region

WITH STOLEN_REGION AS(
			SELECT REGION, MAKE_NAME, COUNT(V.VEHICLE_ID) AS THEFT_COUNT,
	               ROW_NUMBER() OVER (PARTITION BY L.REGION ORDER BY (COUNT(V.VEHICLE_ID))DESC) AS ROW_NUM
			FROM STOLEN_VEHICLES AS V
			JOIN LOCATIONS AS L ON V.LOCATION_ID = L.LOCATION_ID
			JOIN MAKE_DETAILS AS MD ON V.MAKE_ID = MD.MAKE_ID
			GROUP BY 1,2
)
SELECT *
FROM STOLEN_REGION
WHERE ROW_NUM = 1

---Q12:  Create a Function to Get Stolen Vehicles by Region

CREATE OR REPLACE FUNCTION GetStolenVehiclesByRegion(region_name VARCHAR)
RETURNS TABLE (vehicle_id INT, vehicle_type VARCHAR, make_name VARCHAR, model_year INT, color VARCHAR, date_stolen DATE, region VARCHAR)
LANGUAGE plpgsql 
AS $$
BEGIN
    RETURN QUERY 
    SELECT sv.vehicle_id, sv.vehicle_type, md.make_name, sv.model_year, sv.color, sv.date_stolen, l.region
    FROM stolen_vehicles sv
    JOIN make_details md ON sv.make_id = md.make_id
    JOIN locations l ON sv.location_id = l.location_id
    WHERE l.region = region_name;
END;
$$;

--testing function
SELECT * FROM GetStolenVehiclesByRegion('Auckland');


---Q13: Create a Function to Find Top N Most Stolen Vehicle Types

CREATE OR REPLACE FUNCTION GETMOSTSTOLENVEHICLETYPES (TOP_N INT)
RETURNS TABLE (VEHICLE_TYPE VARCHAR, TOTAL_STOLEN INT)
LANGUAGE PLPGSQL
AS $$
BEGIN
    RETURN QUERY
    SELECT V.VEHICLE_TYPE, COUNT(*)::INT AS TOTAL_STOLEN  -- Casting COUNT(*) to INT
    FROM STOLEN_VEHICLES AS V
    GROUP BY V.VEHICLE_TYPE
    ORDER BY TOTAL_STOLEN DESC
    LIMIT TOP_N;
END;
$$;

---testing function
SELECT * FROM GETMOSTSTOLENVEHICLETYPES(5);


---Q14: Find the Region Where Theft Rate is Increasing the Fastest

WITH Theft_By_Year AS (
    SELECT l.region, 
           EXTRACT(YEAR FROM sv.date_stolen) AS theft_year, 
           COUNT(*) AS total_stolen
    FROM stolen_vehicles sv
    JOIN locations l ON sv.location_id = l.location_id
    GROUP BY l.region, theft_year
)
SELECT a.region, a.theft_year, 
       ROUND(((a.total_stolen - b.total_stolen) * 100.0 / b.total_stolen), 2) AS theft_growth_percentage
FROM Theft_By_Year a
JOIN Theft_By_Year b ON a.region = b.region AND a.theft_year = b.theft_year + 1
ORDER BY theft_growth_percentage DESC
LIMIT 1;



SELECT *
FROM LOCATIONS

SELECT *
FROM MAKE_DETAILS

SELECT *
FROM STOLEN_VEHICLES
