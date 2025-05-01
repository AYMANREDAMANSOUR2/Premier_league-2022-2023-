-- Bring me the players I have in Player_Info but not in Player_Stats, or vice versa 
SELECT p.Player AS PlayerInfoName, s.Player AS PlayerStatsName
FROM Player_Info p
FULL OUTER JOIN Player_Stats s
    ON p.Player = s.Player
WHERE p.Player IS NULL OR s.Player IS NULL;
-- This shows players who are only in one table — either in Player_Info or in Player_Stats, but not in both.
SELECT p.Player AS PlayerInfoName, s.Player AS PlayerStatsName
FROM Player_Info p
FULL OUTER JOIN Player_Stats s
    ON TRIM(LOWER(p.Player)) = TRIM(LOWER(s.Player))
WHERE p.Player IS NULL OR s.Player IS NULL;
-- This joins all 3 tables together — Player_Info, Player_Stats, and Salary — and shows all data even if some players exist in one table but not the others.
SELECT * FROM Player_Info pi 
full JOIN Player_Stats ps ON TRIM(LOWER(pi.Player)) = TRIM(LOWER(ps.Player))
full JOIN Salary s ON TRIM(LOWER(pi.Player)) = TRIM(LOWER(s.Player));
--This shows players that are in Player_Stats but missing from Player_Info.
SELECT ps.Player FROM Player_Stats ps
LEFT JOIN Player_Info pi 
ON ps.Player = pi.Player WHERE pi.Player IS NULL;
-- This shows players that are in Salary table but not found in Player_Info.
select s.player from Salary s 
left join Player_Info pi
on s.Player = pi.Player where pi.Player is null ;
-- This shows clubs that appear in Player_Stats but not found in the Teams table.
select ps.Club from Player_Stats ps
left join Teams t 
on ps.Club = t.Squad where t.Squad is null ;

-- Who are the 5 best players in terms of goals? -->
SELECT TOP 5  Player, Club, Goals
FROM Player_Stats
ORDER BY Goals DESC; 

-- If you want to bring players from 6th to 10th place in the goalscoring rankings (meaning skipping the first 5)
SELECT Player, Club, Goals
FROM Player_Stats
ORDER BY Goals DESC
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;

-- Which players have scored more than 10 goals and are not strikers (FW)?
SELECT ps.Player, ps.Club, ps.Goals, ps.Position
FROM Player_Stats ps
WHERE ps.Goals > 10 AND ps.Position <> 'FW';

-- What is the average goals per position?
select ps.Position , AVG(CAST(ps.Goals AS float)) AS AVG_Goals 
from Player_Stats ps group by ps.Position

-- Who are the top 5 highest paid players and their nationalities?
select top 5 s.Player , pi.Nationality , s.Salary From Salary s
Join Player_Info pi ON s.Player = pi.Player order by s.Salary Desc ;

--Which players have salaries above 10 million and goals below 5?
select ps.Player , s.Salary , ps.Goals from Player_Stats ps
join Salary s on ps.Player = s.Player Where s.Salary > 1000000 AND ps.Goals < 5 ;

-- What is the salary per goal ratio for the top 5 scorers?
select top 5 ps.Player , s.Salary , ps.Goals , (s.Salary / ps.Goals) AS Salary_Per_Goal 
From Player_Stats ps join Salary s On ps.Player = s.Player 
where ps.Goals > 0  order by ps.Goals desc

-- Which teams have scored more than 70 goals? 
select t.Squad , t.Goals_For , t.Points from Teams t Where t.Goals_For > 70 ;

-- What is the total player salaries for each team?
select t.Squad , SUM(s.Salary) AS Total_Salary , t.Points From Teams t 
join Player_Stats ps on ps.Club = t.Squad 
join Salary s on ps.Player = s.Player
group by t.Squad , t.Points order by Total_Salary Desc ;

-- Who is the best scorer in each of the top 5 teams?
Select ps.Player , ps.Club , ps.Goals from Player_Stats ps
join Teams t on ps.Club = t.Squad 
where t.Points >= (select Points from Teams order by Points Desc offset 4 rows fetch Next 1 row only)
and ps.Goals = (select max(ps2.Goals) from Player_Stats ps2 where ps2.Club = ps.Club) ; 

-- in other way we can do this (the best way)
WITH Top5Teams AS (
    SELECT TOP 5 Squad , Points FROM Teams ORDER BY Points DESC
) -- here i just get the top 5 squad depending on their points 
SELECT ps.Player, ps.Club, ps.Goals
FROM Player_Stats ps
JOIN Top5Teams t5 ON ps.Club = t5.Squad -- to get the palyers whos in these teams 
WHERE ps.Goals = (
    SELECT MAX(ps2.Goals)
    FROM Player_Stats ps2
    WHERE ps2.Club = ps.Club
); 
 -- i only have arsenal , liver and city data for the top 5 teams now
SELECT DISTINCT Club FROM Player_Stats 
WHERE Club IN (
  SELECT TOP 5 Squad FROM Teams 
  ORDER BY Points DESC
);



-- Which players have scored more than 10 goals, along with their salaries and team points?
select top 10 pi.Player , pi.Nationality , ps.Goals , s.Salary , t.Squad , t.Points 
from Player_Info pi join Player_Stats ps on pi.Player = ps.Player 
join Teams t on t.Squad = ps.Club
join Salary s on s.Player = pi.Player 
where ps.Goals > 10 order by ps.Goals ;

-- Which nationality has scored the most goals?
SELECT TOP 5 pi.Nationality, SUM(ps.Goals) AS Total_Goals
FROM Player_Info pi JOIN Player_Stats ps ON pi.Player = ps.Player
GROUP BY pi.Nationality
ORDER BY Total_Goals DESC;

-- Which teams have above average height players and score a lot of goals?
SELECT t.Squad, AVG(CAST(pi.Height AS FLOAT)) AS Avg_Height, SUM(ps.Goals) AS Total_Goals
FROM Player_Info pi JOIN Player_Stats ps ON pi.Player = ps.Player
JOIN Teams t ON ps.Club = t.Squad
GROUP BY t.Squad
HAVING AVG(CAST(pi.Height AS FLOAT)) > (SELECT AVG(CAST(Height AS FLOAT)) FROM Player_Info)
ORDER BY Total_Goals DESC;


-- alisson has 2 salary , we will delete one                                                                       
select s.Player , s.Salary from Salary s where s.Player = 'Alisson Becker'
DELETE FROM Salary
WHERE Player = 'Alisson Becker' AND Salary = 4680000;

--                                    using View                                                                  
go
CREATE VIEW TopPlayersView AS
SELECT pi.Player, pi.Nationality, ps.Goals, ps.Position, s.Salary, t.Squad, t.Points
FROM Player_Info pi JOIN Player_Stats ps ON pi.Player = ps.Player
LEFT JOIN Salary s ON pi.Player = s.Player -- left to show all players even if they don't have salary
JOIN Teams t ON ps.Club = t.Squad 
WHERE ps.Goals > 0; 
go


SELECT TOP 5 Player, Nationality, Goals, Squad, Salary
FROM TopPlayersView
ORDER BY Goals DESC;
-- hary kain doesnt appear !! there is a problem here we gonna check the data 

SELECT Player, Nationality, Goals, Squad, Salary
FROM TopPlayersView
WHERE Player = 'Harry Kane';
-- check the view in harry kain only --  still doesnt appear 
-- we gonna to trim the data to check if there's a space or something like 
UPDATE Player_Info  SET Player = TRIM(Player);
UPDATE Player_Stats SET Player = TRIM(Player);
UPDATE Salary       SET Player = TRIM(Player);
UPDATE Player_Stats SET Club = TRIM(Club);
UPDATE Teams        SET Squad = TRIM(Squad);
-- still doesnt appear , we must check the team's name  (the problem here)
SELECT DISTINCT Club FROM Player_Stats WHERE Club LIKE '%Tottenham%'; --> Tottenham Hotspur
SELECT Squad FROM Teams WHERE Squad LIKE '%Tottenham%'; --> Tottenham
-- so we wanna edit this
UPDATE Player_Stats SET Club = 'Tottenham' WHERE Club = 'Tottenham Hotspur';


-- we must drop and build the view agin 
DROP VIEW TopPlayersView; 
GO
CREATE VIEW TopPlayersView AS
SELECT pi.Player, pi.Nationality, ps.Goals, ps.Position, s.Salary, t.Squad, t.Points
FROM Player_Info pi
INNER JOIN Player_Stats ps ON pi.Player = ps.Player
LEFT JOIN Salary s ON pi.Player = s.Player
INNER JOIN Teams t ON ps.Club = t.Squad
WHERE ps.Goals > 0;
GO

--										PlayerPerformanceView														
go
Create view PlayerPerformanceView AS
SELECT ps.Player, ps.Club, ps.Position, ps.Goals, ps.Assists, ps.Shots, ps.Shots_on_Target, pi.Height
FROM Player_Stats ps JOIN Player_Info pi ON ps.Player = pi.Player;
go

SELECT Player, Club, Position, Goals, Assists, Shots, Shots_on_Target, Height
from PlayerPerformanceView 
order by Goals desc 
--                                      TeamSalariesView                                            
go
CREATE VIEW TeamSalariesView AS
SELECT t.Squad, SUM(s.Salary) AS Total_Salary, t.Points, t.Goals_For, t.Goals_Against
FROM Teams t
JOIN Player_Stats ps ON ps.Club = t.Squad
LEFT JOIN Salary s ON ps.Player = s.Player
GROUP BY t.Squad, t.Points, t.Goals_For, t.Goals_Against;
go
--								 Stored Procedure: GetTopScorers         with views                       
CREATE PROCEDURE GetTopScorers
    @TopN INT -- the num. of players whos i wanna get them
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@TopN) Player, Nationality, Goals, Squad, Salary
    FROM TopPlayersView
    ORDER BY Goals DESC;
END;
GO

exec GetTopScorers @TopN = 5 ; 

--						   Stored Procedure: GetTeamSalaryStats         using view (TeamSalariesView)      
go
create procedure GetTeamSalaryStats 
	@MinTotalSalary Decimal(15,2) = 0
AS
begin 
	set NOCOUNT on ;
	select Squad, Total_Salary, Points, Goals_For, Goals_Against
	from TeamSalariesView 
	where Total_Salary >= @MinTotalSalary 
	order by Total_Salary desc ;
end 
go

exec GetTeamSalaryStats @MinTotalSalary = 40000000

