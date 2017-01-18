--By: Jana Sattainathan [Twitter: @SQLJana] [Blog: sqljana.wordpress.com]
--________________________________________________________________________
USE Util
GO


--We will look at this in a minute but please hold for now!
--------------------------------------
UPDATE Logging.LogAppMaster
SET LogAutonomously = 1
WHERE AppContextInfo = '[DEFAULT]';






---------------------------------------------------------------------------------------------------------------
--Demo 3 - Transactions
---------------------------------------------------------------------------------------------------------------


--Nested transactions are a myth...in SQL Server - Paul Randall
--http://www.sqlskills.com/blogs/paul/a-sql-server-dba-myth-a-day-2630-nested-transactions-are-real/

--Create a table named TxnTest from our Logging.Log table!
SELECT *
INTO TxnTest
FROM Logging.Log;


SELECT *
FROM TxnTest;


--Note the record count
-- 12


WAITFOR DELAY '00:01'		-- wait for 1 minute
GO


------------------------------------------------------------------------------------------------------



--Straight-forward transaction


BEGIN TRANSACTION OuterTxn;

--Count BEFORE delete
SELECT COUNT(1) AS BeforeDelete FROM TxnTest;

DELETE FROM TxnTest WHERE LogId IN
	(SELECT TOP 5 LogId FROM TxnTest);

SELECT @@TRANCOUNT AS 'Transaction Count'

--Count AFTER delete
SELECT COUNT(1) AS AfterDelete  FROM TxnTest;

ROLLBACK;

--Count AFTER rollback;
SELECT COUNT(1)  AS AfterRollback FROM TxnTest;




WAITFOR DELAY '00:01'		-- wait for 1 minute
GO


------------------------------------------------------------------------------------------------------






--Nested transaction - wont work when you try to rollback inner transaction

-------------------
--Outer transaction
-------------------
BEGIN TRANSACTION OuterTxn;

DELETE FROM TxnTest WHERE LogId IN
	(SELECT TOP 5 LogId FROM TxnTest);

	-------------------
	--Inner transaction
	-------------------
	BEGIN TRANSACTION InnerTxn;

	DELETE FROM TxnTest WHERE LogId IN
		(SELECT TOP 5 LogId FROM TxnTest);

	ROLLBACK TRANSACTION InnerTxn;


ROLLBACK;




WAITFOR DELAY '00:01'		-- wait for 1 minute
GO


------------------------------------------------------------------------------------------------------



--Outer transaction ROLLBACK failure (after inner transaction rollback) demo...

-------------------
--Outer transaction
-------------------
BEGIN TRANSACTION OuterTxn;

--Count BEFORE delete
SELECT COUNT(1) AS BeforeOuterDelete FROM TxnTest;

DELETE FROM TxnTest WHERE LogId IN
	(SELECT TOP 5 LogId FROM TxnTest ORDER BY LogId);

--Count OUTER delete
SELECT COUNT(1) AS AfterOuterDelete  FROM TxnTest;

SELECT @@TRANCOUNT AS 'Transaction Count - Outer'

	-------------------
	--Inner transaction
	-------------------
	BEGIN TRANSACTION InnerTxn;

	DELETE FROM TxnTest WHERE LogId IN
		(SELECT TOP 5 LogId FROM TxnTest ORDER BY LogId);

	SELECT @@TRANCOUNT AS 'Transaction Count - Inner'

	--Count INNER delete
	SELECT COUNT(1) AS AfterInnerDelete  FROM TxnTest;

	--This rolls back everything (inner and outer)
	ROLLBACK;


	SELECT @@TRANCOUNT AS 'Transaction Count - After - Inner rollback'



--Count AFTER inner rollback
SELECT COUNT(1) AS AfterInnerRollback FROM TxnTest;

--________

--NOTICE: THIS ROLLBACK FAILS! THE ROLLBACK IN THE INNER TRANSACTION ROLLED BACK EVERYTHING!
--________

ROLLBACK;

SELECT @@TRANCOUNT AS 'Transaction Count - After - Outer rollback'

--Count AFTER rollback;
SELECT COUNT(1)  AS AfterRollbackAll FROM TxnTest;





WAITFOR DELAY '00:01'		-- wait for 1 minute
GO


------------------------------------------------------------------------------------------------------




--Outer transaction ROLLBACK failure (after inner transaction rollback) demo...



DECLARE @LogId BIGINT;
DECLARE @AppContextInfo VARBINARY(128) =  CAST('Transaction Checker' AS  VARBINARY(128))
DECLARE @Msg VARCHAR(255) = 'Test transactions';
 
SET CONTEXT_INFO @AppContextInfo


-------------------
--Outer transaction
-------------------
BEGIN TRANSACTION OuterTxn;
EXEC Logging.StartLog @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = 'Begin OuterTxn!', @LogId = @LogId OUTPUT;
EXEC Logging.EndLog @LogId = @LogId

--Count BEFORE outer delete
EXEC Logging.StartLog @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = 'Count BEFORE outer delete!', @LogId = @LogId OUTPUT;
SELECT COUNT(1) AS BeforeOuterDelete FROM TxnTest;
EXEC Logging.EndLog @LogId = @LogId

--Outer delete
EXEC Logging.StartLog @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = 'Outer delete!', @LogId = @LogId OUTPUT;
DELETE FROM TxnTest WHERE LogId IN
	(SELECT TOP 5 LogId FROM TxnTest ORDER BY LogId);
EXEC Logging.EndLog @LogId = @LogId

--Count OUTER delete
EXEC Logging.StartLog @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = 'Count after outer delete!', @LogId = @LogId OUTPUT;
SELECT COUNT(1) AS AfterOuterDelete  FROM TxnTest;
EXEC Logging.EndLog @LogId = @LogId


SELECT @@TRANCOUNT AS 'Transaction Count - Outer'

	-------------------
	--Inner transaction
	-------------------
	EXEC Logging.StartLog @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = 'Began InnerTxn!', @LogId = @LogId OUTPUT;
	BEGIN TRANSACTION InnerTxn;
	EXEC Logging.EndLog @LogId = @LogId

	EXEC Logging.StartLog @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = 'Inner DELETE done!', @LogId = @LogId OUTPUT;
	DELETE FROM TxnTest WHERE LogId IN
		(SELECT TOP 5 LogId FROM TxnTest ORDER BY LogId);
	EXEC Logging.EndLog @LogId = @LogId

	SELECT @@TRANCOUNT AS 'Transaction Count - Inner'

	--Count INNER delete
	EXEC Logging.StartLog @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = 'Count after INNER DELETE done!', @LogId = @LogId OUTPUT;
	SELECT COUNT(1) AS AfterInnerDelete  FROM TxnTest;
	EXEC Logging.EndLog @LogId = @LogId

	
	ROLLBACK;


	EXEC Logging.StartLog @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = 'Transaction count after inner rollback!', @LogId = @LogId OUTPUT;
	SELECT @@TRANCOUNT AS 'Transaction Count - After - Inner rollback'
	EXEC Logging.EndLog @LogId = @LogId


--Count AFTER inner rollback
EXEC Logging.StartLog @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = 'Count after inner rollback!', @LogId = @LogId OUTPUT;
SELECT COUNT(1) AS AfterInnerRollback FROM TxnTest;
EXEC Logging.EndLog @LogId = @LogId

--________

--NOTICE: WE KNOW THAT THIS ROLLBACK WILL FAIL! THE ROLLBACK IN THE INNER TRANSACTION ROLLED BACK EVERYTHING!
--________

--EXEC Logging.StartLog @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = 'Rolling back outer!', @LogId = @LogId OUTPUT;
--ROLLBACK;
--EXEC Logging.EndLog @LogId = @LogId

SELECT @@TRANCOUNT AS 'Transaction Count - After - Outer rollback'

--Count AFTER rollback;
EXEC Logging.StartLog @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = 'Final count after all rolllbacks!', @LogId = @LogId OUTPUT;
SELECT COUNT(1)  AS AfterRollbackAll FROM TxnTest;
EXEC Logging.EndLog @LogId = @LogId


--Notice how the record counts of deleted rows and trasaction nesting level are automatically recorded!
SELECT LogId, LogDate, AppContextInfo, AdditionalInfo, TransactionCount, RowsAffected, DurationMilliseconds 
FROM Logging.Log ORDER BY LogId DESC;





WAITFOR DELAY '00:01'		-- wait for 1 minute
GO


------------------------------------------------------------------------------------------------------






--Wait a minute.....Does anyone trust this?  Why or why not?



WAITFOR DELAY '00:01'		-- wait for 1 minute
GO





------------------------------------------------------------------------------------------------------















--All transactions should have been rolled back
--
-- Logging operations are transactions too...
--
--How did they survive?


-- LoopBack linked server helps us do that by isolating the transaction
-- ...could alternatively use .NET CLR procedure..

--We will walk through code shortly..



--Doing the default ROLLBACK behavior...ROLLBACK rolls back logs too...
--------------------------------------
UPDATE Logging.LogAppMaster
SET LogAutonomously = 0
WHERE AppContextInfo = '[DEFAULT]';


--What is our latest log entry?
SELECT MAX(LogId) AS MaxLogId
FROM Logging.Log;


DECLARE @LogId BIGINT;
DECLARE @AppContextInfo VARBINARY(128) =  CAST('Transaction Checker - non-autonomous' AS  VARBINARY(128))
DECLARE @Msg VARCHAR(255) = 'Test transactions - non-autonomous';


BEGIN TRANSACTION OuterTxn;
EXEC Logging.StartLog @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = 'Begin OuterTxn!', @LogId = @LogId OUTPUT;
EXEC Logging.EndLog @LogId = @LogId

	-------------------
	--Inner transaction
	-------------------
	EXEC Logging.StartLog @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = 'Began InnerTxn!', @LogId = @LogId OUTPUT;
	BEGIN TRANSACTION InnerTxn;
	EXEC Logging.EndLog @LogId = @LogId

	ROLLBACK;





--What is our latest log entry now after ROLLBACK?
SELECT MAX(LogId) AS MaxLogId
FROM Logging.Log;



--No change in logs now! Logs got rolled back too..




--View Logging.LogAppMaster table and its contents...



--Update back to 1 for LogAutonomously
UPDATE Logging.LogAppMaster
SET LogAutonomously = 1
WHERE AppContextInfo = '[DEFAULT]';


