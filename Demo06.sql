--By: Jana Sattainathan [Twitter: @SQLJana] [Blog: sqljana.wordpress.com]
--________________________________________________________________________
USE Util
GO




------------------------------------------------------------------------------------------------------


    ---------------
    --Example
    ---------------
    --In this example, we will see how to work with loops when processing large number of items without cluttering the log!
	--DO NOT do logging inside a loop like this for every loop iteration!
	--(if you do, do it after every x iterations in the loop as this example shows!)

        ------------------------ Begin: Logging related ------------------------
    DECLARE @DBId BIGINT = DB_ID();
    DECLARE @ObjId BIGINT = @@PROCID;
    DECLARE @ParentObjId BIGINT = NULL;     --Set to NULL if no @CallerProcId parameter
    DECLARE @LogId BIGINT;
    DECLARE @Msg VARCHAR(255);
    DECLARE @StepLogId BIGINT;
    DECLARE @StepMsg VARCHAR(255);
    DECLARE @Tag VARCHAR(512) = NULL;         --Set to NULL if no @CallerTag parameter
        ------------------------ End: Logging related ------------------------
 

	-------------------------------------------------------------
	SET @StepMsg = 'Loop through 100000 items';
	------------------------------------------------------------
	EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT --Log step start
	
	--Create a table and insert into the table
	--------------------------------------------
	CREATE TABLE dbo.T1 (Col1 int, Col2 char(3));  	

	DECLARE @LoopLogId INT
	DECLARE @i int = 0;  
	BEGIN TRAN  

	SET @i = 0;  
	WHILE (@i < 100000)  
	BEGIN  

		--Only log every 10,000 iterations
		IF (@i % 10000) = 0
		BEGIN
			-------------------------------------------------------------
			SET @StepMsg = 'Processing ' + STR(@i) + ' of 100000 items';
			------------------------------------------------------------
	
			EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'LOOP', @AdditionalInfo = @StepMsg, @LogId = @LoopLogId OUTPUT
		END;

		INSERT INTO dbo.T1 VALUES (@i, CAST(@i AS char(3)));  
		SET @i += 1;  

		--Close-out the loop entry so that end-time will be recorded for this iteration
		IF (@i % 10000) = 0
		BEGIN
			EXEC EndLog @LogID = @LoopLogId; --Log loop end
		END;
	END;  
	COMMIT TRAN;  

	EXEC EndLog @LogID = @LogId; --End of process

	DROP TABLE dbo.T1




	SELECT AdditionalInfo, * FROM Logging.Log ORDER BY LogId DESC;

 
 
WAITFOR DELAY '00:01'		-- wait for 1 minute
GO




------------------------------------------------------------------------------------------------------



	---------------
    --Example 7
    ---------------
    --In this example, we will see how to work with loops. 
	--	Logging every iteration since loop is small or essential to log!
	
        ------------------------ Begin: Logging related ------------------------
    DECLARE @DBId BIGINT = DB_ID();
    DECLARE @ObjId BIGINT = @@PROCID;
    DECLARE @ParentObjId BIGINT = NULL;     --Set to NULL if no @CallerProcId parameter
    DECLARE @LogId BIGINT;
    DECLARE @Msg VARCHAR(255);
    DECLARE @StepLogId BIGINT;
    DECLARE @StepMsg VARCHAR(255);
    DECLARE @Tag VARCHAR(512) = NULL;         --Set to NULL if no @CallerTag parameter
        ------------------------ End: Logging related ------------------------

	------------------------------------------------------------
	SET @StepMsg = 'Get the list of objects';
	------------------------------------------------------------
	EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT --Log step start
 
	SELECT *
	INTO #ControlTable
	FROM sys.objects;

	------------------------------------------------------------
	SET @StepMsg = 'Loop through objects and process each';
	------------------------------------------------------------
	EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT --Log step start
 
	DECLARE @object_id BIGINT = NULL;
	DECLARE @LoopLogId INT = 0;
	
	WHILE EXISTS (SELECT 1 FROM #ControlTable)
	BEGIN
 
		SELECT TOP 1
			@object_id = object_id
		FROM #ControlTable
		ORDER BY Object_Id asc;
 
		------------------------------------------------------------
		SET @StepMsg = 'Process object_id: ' + STR(@object_id);
		------------------------------------------------------------
		EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'LOOP', @AdditionalInfo = @StepMsg, @LogId = @LoopLogId OUTPUT --Log step start
 
		PRINT 'Working with object'
 
		EXEC EndLog @LogID = @LoopLogId; --Log loop end

		DELETE FROM #ControlTable
		WHERE object_id = @object_id
	END;

	DROP TABLE #ControlTable



	SELECT AdditionalInfo, * FROM Logging.Log ORDER BY LogId DESC;

 


 
WAITFOR DELAY '00:01'		-- wait for 1 minute
GO




------------------------------------------------------------------------------------------------------


