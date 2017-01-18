
--By: Jana Sattainathan [Twitter: @SQLJana] [Blog: sqljana.wordpress.com]
--________________________________________________________________________
USE Util
GO

---------------------------------------------------------------------------------------------------------------
--Demo 1 - Be easy to use with defaults yet have all options for the advanced user
---------------------------------------------------------------------------------------------------------------

--Base idea by Aaron Bertrand
--https://www.mssqltips.com/sqlservertip/2003/simple-process-to-track-and-log-sql-server-stored-procedure-use/

--Simple and elegant logging but could not satisfy advanced logging needs
--View the page and show the pieces involved....



--Our (advanced! NOT) version involves a bit more
--View the tables/procedures/linked server and views involved



--Let us truncate the Log table to get a clean start and view results as we go
TRUNCATE TABLE Logging.Log;
GO


--Basic logging:
------------------------------------------------------------------------------------------------------

---------------
--Example 1
---------------
--Example 1.1 - Simplest call - With no parameters
EXEC StartLog


SELECT * FROM Logging.Log ORDER BY LogId DESC;

--We have a lot of useful information but there is not context!


 
WAITFOR DELAY '00:01'		-- wait for 1 minute
GO

 
------------------------------------------------------------------------------------------------------


--Get back LogID of the entry just logged + add a status message!

DECLARE @LogId BIGINT;
EXEC StartLog @AdditionalInfo = 'Some status message', @LogId = @LogId OUTPUT;
PRINT @LogId

SELECT * FROM Logging.Log ORDER BY LogId DESC;

--Notice the AdditionalInfo column with status message + we printed out @LogId




 
WAITFOR DELAY '00:01'		-- wait for 1 minute
GO




------------------------------------------------------------------------------------------------------


--Example 1.2 - ..+ ObjectId is included
DECLARE @LogId BIGINT;
EXEC StartLog @ObjectID = @@PROCID, @AdditionalInfo = 'Adding ObjectId', @LogId = @LogId OUTPUT;

PRINT @LogId

SELECT * FROM Logging.Log ORDER BY LogId DESC;

--Notice the AdditionalInfo, @LogID printed out + ObjectId column filled.
--	ObjectId is not meaningful in this context but will be useful when logging procedures


WAITFOR DELAY '00:01'		-- wait for 1 minute
GO





------------------------------------------------------------------------------------------------------



 
--Example 1.3 - ..+ Status message + Log type is included
DECLARE @LogId BIGINT;
EXEC StartLog @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = 'About to run my stats calcuation step', @LogId = @LogId OUTPUT;

PRINT @LogId

SELECT * FROM Logging.Log ORDER BY LogId DESC;

/*
Notice the LogType column

LogTypes allowed are - 
	ANONYMOUS BLOCK
	BATCH
	PROCESS
	APPLICATION
	MODULE
	PROCEDURE
	FUNCTION
	STEP
	SQL
	LOOP

Useful in tracking different things and track them simultaneously too
...e.g., PROCEDURE has STEPS and calls other procedures with STEPS and LOOPs
			All of these may be open and have to be tracked simultaneously
*/


WAITFOR DELAY '00:01'		-- wait for 1 minute
GO






------------------------------------------------------------------------------------------------------

 
--Example 1.4 - ..+ ParentObjectID is included
DECLARE @LogId BIGINT;
DECLARE @ParentObjectId BIGINT;
 
SET @ParentObjectId = OBJECT_ID('[Util].[Logging].[StartLog]')
EXEC StartLog @ObjectID = @@PROCID, @ParentObjectID = @ParentObjectId, @LogType = 'STEP', @AdditionalInfo = 'ParentLogId included!', @LogId = @LogId OUTPUT;



--Notice the ParentLogId column filled
SELECT * FROM Logging.Log ORDER BY LogId DESC


--With ParentObjectId and ObjectId filled, we can analyze the hierarchy relationship of the calls...
--Typically, ParentObjectId and ObjectId's are set in each procedure call 
--	...but we will see how to avoid having to track that!



--Assuming all code is instrumented, we can possibly query the logs to get the call hierarchy in this form
-- Source: http://stackoverflow.com/questions/9380620/parent-child-hierarchy-tree-view

declare @pc table(CHILD_ID int, PARENT_ID int, [NAME] varchar(80));
 
insert into @pc
select 1,NULL,'Bill' union all
select 2,1,'Jane' union all
select 3,1,'Steve' union all
select 4,2,'Ben' union all
select 5,3,'Andrew' union all
select 6,NULL,'Tom' union all
select 7,8,'Dick' union all
select 8,6,'Harry' union all
select 9,3,'Stu' union all
select 10,7,'Joe';
 
 
; with r as (
      select CHILD_ID, PARENT_ID, [NAME], depth=0, sort=cast(CHILD_ID as varchar(max))
      from @pc
      where PARENT_ID is null
      union all
      select pc.CHILD_ID, pc.PARENT_ID, pc.[NAME], depth=r.depth+1, sort=r.sort+cast(pc.CHILD_ID as varchar(30))
      from r
      inner join @pc pc on r.CHILD_ID=pc.PARENT_ID
      where r.depth<32767
)
select tree=replicate('-',r.depth*3)+r.[NAME]
from r
order by sort
option(maxrecursion 32767);




WAITFOR DELAY '00:01'		-- wait for 1 minute
GO






------------------------------------------------------------------------------------------------------




 
--Example 1.5 - ..+ DatbaseID is included
DECLARE @LogId BIGINT;
DECLARE @DatabaseId BIGINT = DB_ID();
DECLARE @ParentObjectId BIGINT = OBJECT_ID('[Util].[Logging].[StartLog]');
 
EXEC StartLog @DatabaseId = @DatabaseId, @ObjectID = @@PROCID, @ParentObjectID = @ParentObjectId, @LogType = 'STEP', @AdditionalInfo = 'Added DatabaseId although it was detected before!', @LogId = @LogId OUTPUT;



SELECT * FROM Logging.Log ORDER BY LogId DESC;

--Notice the DatabaseName column has always been filled for us anyway!


WAITFOR DELAY '00:01'		-- wait for 1 minute
GO










------------------------------------------------------------------------------------------------------



--Example 1.6 - Running from another database - master

USE master
GO


DECLARE @LogId BIGINT;
DECLARE @DatabaseId BIGINT = DB_ID();
DECLARE @ParentObjectId BIGINT = OBJECT_ID('[Util].[Logging].[StartLog]');
 
EXEC Util.Logging.StartLog @DatabaseId = @DatabaseId, @ObjectID = @@PROCID, @ParentObjectID = @ParentObjectId, @LogType = 'STEP', @AdditionalInfo = 'Added DatabaseId although it was detected before!', @LogId = @LogId OUTPUT;




SELECT * FROM Util.Logging.Log ORDER BY LogId DESC;

--Notice the DatabaseName column changed to 'master'!



--A better way to reference Util.Logging.StartLog is by using Synonyms!



USE Util
GO

WAITFOR DELAY '00:01'		-- wait for 1 minute
GO





------------------------------------------------------------------------------------------------------



--Example 1.7 - Closing out log entries for Duration etc..

USE master
GO


DECLARE @LogId BIGINT;
DECLARE @DatabaseId BIGINT = DB_ID();
DECLARE @ParentObjectId BIGINT = OBJECT_ID('[Util].[Logging].[StartLog]');
 
EXEC Util.Logging.StartLog @DatabaseId = @DatabaseId, @ObjectID = @@PROCID, @ParentObjectID = @ParentObjectId, @LogType = 'STEP', @AdditionalInfo = 'Deleting a couple of rows!', @LogId = @LogId OUTPUT;

WAITFOR DELAY '00:00:05'		-- wait for 5 seconds

--Delete two records
DELETE FROM Util.Logging.Log 
WHERE LogId IN (SELECT TOP 2 LogId 
				FROM Util.Logging.Log 
				ORDER BY LogId);

--EndLog closes out the log entry to record end-time and duration
EXEC Util.Logging.EndLog @LogId = @LogId

--Notice these columns - LogDate,EndDateTime,DurationMilliseconds, RowsAffected 
SELECT AdditionalInfo, LogDate,EndDateTime,DurationMilliseconds, RowsAffected, *
FROM Util.Logging.Log ORDER BY LogId DESC;


--We did not do anything to record the count of rows deleted...
--..but we have 2 in RowsAffected column 
--The call to EndLog did it automatically using @@ROWCOUNT


------------------------------------------------------------------------------------------------------





--Example 1.8 - Recording errors automatically

USE master
GO


DECLARE @LogId BIGINT;
DECLARE @DatabaseId BIGINT = DB_ID();
DECLARE @ParentObjectId BIGINT = OBJECT_ID('[Util].[Logging].[StartLog]');

BEGIN TRY 

	EXEC Util.Logging.StartLog @DatabaseId = @DatabaseId, @ObjectID = @@PROCID, @ParentObjectID = @ParentObjectId, @LogType = 'STEP', @AdditionalInfo = 'Generating error!', @LogId = @LogId OUTPUT;

	SELECT 1/0;

	--EndLog closes out the log entry to record end-time and duration
	EXEC Util.Logging.EndLog @LogId = @LogId

END TRY
BEGIN CATCH

	--EndLog closes out the log entry to record end-time and duration
	EXEC Util.Logging.EndLog @LogId = @LogId

END CATCH;

--Notice these columns - LogDate,EndDateTime,DurationMilliseconds, RowsAffected 
SELECT AdditionalInfo,LogDate,EndDateTime,ErrorLine, ErrorMessage, *
FROM Util.Logging.Log ORDER BY LogId DESC;


--Again, the error detection automatically detected the errors 
--..and recorded it
--The call to EndLog did it automatically using @@ERROR_LINE & @@ERROR_MESSAGE



WAITFOR DELAY '00:01'		-- wait for 1 minute
GO


------------------------------------------------------------------------------------------------------



USE Util
GO

WAITFOR DELAY '00:01'		-- wait for 1 minute
GO


