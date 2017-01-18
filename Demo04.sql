--By: Jana Sattainathan [Twitter: @SQLJana] [Blog: sqljana.wordpress.com]
--________________________________________________________________________
USE Util
GO



---------------------------------------------------------------------------------------------------------------
--Demo 4 - XML
---------------------------------------------------------------------------------------------------------------

	
    --In this example, we record a lot of additional information in a structured manner (XML) in the Tag column that is queryable later
    --      Notice, how "MontlyRetroRun" is used as the root node and later query against the log table uses that
 
        DECLARE @LogId BIGINT;
        DECLARE @Msg VARCHAR(255) = 'Process customer records';
 
        DECLARE @Tag VARCHAR(512) = '<MonthlyRetroRun> ' +
                                        '<ProcessName>MonthlyRetro</ProcessName>' +
                                        '<ReportToDate><<REPORTTODATE>></ReportToDate>' +
                                        '<RetroCessionMonthlyActivityLogId><<RETROCESSIONMONTHLYACTIVITYLOGID>></RetroCessionMonthlyActivityLogId>' +
                                        '<BatchNumber><<BATCHNUMBER>></BatchNumber>' +
                                        '<RunSequenceNumber><<RUNSEQUENCENUMBER>></RunSequenceNumber>' +
                                    '</MonthlyRetroRun>';
 
        ------------------------ Begin: Tag ------------------------
        --Replace placeholders in the Tag
        SET @Tag = REPLACE(@Tag, '<<REPORTTODATE>>', CONVERT(VARCHAR,getdate()));
        SET @Tag = REPLACE(@Tag, '<<RETROCESSIONMONTHLYACTIVITYLOGID>>', 232121);
        SET @Tag = REPLACE(@Tag, '<<BATCHNUMBER>>', LTRIM(STR(11)));
        SET @Tag = REPLACE(@Tag, '<<RUNSEQUENCENUMBER>>', LTRIM(STR(99999)));
 
        SET @Msg = 'Fetch/decide on values for decision making variables!'
        EXEC StartLog @Tag = @Tag, @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = @Msg, @LogId = @LogId OUTPUT     --Log procedure start
        ------------------------ End: Tag ------------------------  
 
        --At this point, you can select the log entry from Log where
        SELECT r.value('RunSequenceNumber[1]','INT') AS RunNumber,
                r.value('ReportToDate[1]','DateTime') AS ReportToDate,
                l.*
        FROM   Log l
            CROSS APPLY Tag.nodes('/MonthlyRetroRun') AS Runs(r)
 

		EXEC Logging.EndLog @LogId = @LogId
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 


	--Let us look at the xml data in the Log table
	SELECT Tag, * FROM Logging.Log ORDER BY LogId DESC;
 
 
 
    -------------------------------------------
    --Examples that illustrate working with XML
    -------------------------------------------
 
    --Example 1
    -- Querying XML data column "Tag"
        --If Log.Tag column has the value "<MonthlyRetroRun RunId="1">Test</MonthlyRetroRun>", one could query like this.
        -- Reference: http://thegrayzone.co.uk/blog/2010/03/querying-sql-server-xml-data/
        SELECT r.value('MonthlyRetroRun[1]','varchar(15)') AS MonthlyRetroRunName, l.*
        FROM   Log l
        CROSS APPLY Tag.nodes('/') AS Runs(r)
 


    --Example 2
    -- Somewhat more complex querying of XML data column "Tag"
        UPDATE Log
        SET Tag = '<MonthlyRetroRun ReportToDate="' + CONVERT(VARCHAR(25), CONVERT(datetime, '2014-02-28 00:00:00.000')) + '"> ' +
                                        '<ReportToDate>' + CONVERT(VARCHAR(25), CONVERT(datetime, '2014-02-28 00:00:00.000')) + '</ReportToDate>' +
                                        '<RunNumber>1</RunNumber>' +
                                        '<BatchSize>' + LTRIM(STR(1000)) + '</BatchSize>' +
                                        '<MaxRecords>' + LTRIM(STR(50000)) + '</MaxRecords>' +
                                    '</MonthlyRetroRun>'
        WHERE LogId = (SELECT MAX(LogId) FROM Logging.Log);
 



        SELECT r.value('RunNumber[1]','INT') AS RunNumber,
                r.value('ReportToDate[1]','DateTime') AS ReportToDate, 
				l.*
        FROM   Log l
            CROSS APPLY Tag.nodes('/MonthlyRetroRun') AS Runs(r)
        WHERE LogId = (SELECT MAX(LogId) FROM Logging.Log);
 
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 


 --Let us look at the raw data once more
 SELECT *
 FROM Logging.Log
 ORDER BY LogId DESC;

 --Notice the Tag column...
 --	We can put anything business specific in the Tag column
 --		and later query for specifics as we did above...




 
 
WAITFOR DELAY '00:01'		-- wait for 1 minute
GO




------------------------------------------------------------------------------------------------------





 

 --A note about temporary stored procedures!...what they are and how they work


 --Procedure call chains and role of AppContextInfo & Tag in tying re-usuable code together for a run!



 
 --We can make the tag be the same for all entries for session,
 --  even though procedures involved do not directly deal with Tags..

 


	---------------
    --Example 0 - A complete example. Use this as a template for your own code. 
	--				We have an entry point procedure called #MainProc which calls #LoggingTestProc and #LoggingTestProcBare 
    ---------------
	--We set AppContextInfo, Tag and ParentObjectId in #MainProc
	--

 
        --Drop and recreate if our temporary demo procedures already exist..we will call it later to illustrate
        -------------------------------------------------------------------------------------------------------------
 
        IF object_id('TEMPDB.DBO.#MainProc') IS NOT NULL
            DROP PROCEDURE #MainProc;
        GO
 
        CREATE PROCEDURE #MainProc
        AS
        BEGIN
            ------------------------ Begin: Logging related ------------------------
            --Setting context for application (Do this only once in the entry-point procedure for the whole application/batch)
            --  ***** W A R N I N G *****: DO NOT SET THIS IN EVERY PROCEDURE!!
 
            DECLARE @AppContextInfo VARBINARY(128) =  CAST('My Test Application' AS  VARBINARY(128))
 
            --This information will be associated with the session and will be accessible in SQL Server system views
            SET CONTEXT_INFO @AppContextInfo        
 
            DECLARE @Tag VARCHAR(512) = '<TestApplication> ' +
                                            '<ProcessName>Test process</ProcessName>' +
                                            '<ReportToDate><<REPORTTODATE>></ReportToDate>' +
                                            '<LogId><<LOGID>></LogId>' +
                                            '<RunNumber><<RUNNUMBER>></RunNumber>' +
                                        '</TestApplication>';
            DECLARE @CallerProcId BIGINT = @@PROCID;            
 
            EXEC Logging.SetAttribute @AttributeName='Log.ParentObjectId', @AttributeValue=@CallerProcId, @AttributeType='BIGINT', @AttributeFormat=NULL;
            ------------------------ End: Logging related ------------------------
 
            ------------------------ Begin: Tag ------------------------
            --Replace placeholders in the Tag
            SET @Tag = REPLACE(@Tag, '<<REPORTTODATE>>', CONVERT(VARCHAR,getdate()));
            SET @Tag = REPLACE(@Tag, '<<LOGID>>', 232121);
            --SET @Tag = REPLACE(@Tag, '<<RUNNUMBER>>', NEXT VALUE FOR MySchema.RunNumberSeq);      --MySchema.RunNumberSeq is a pre-defined sequence object
            SET @Tag = REPLACE(@Tag, '<<RUNNUMBER>>', 12);
 
            EXEC Logging.SetAttribute @AttributeName='Log.Tag', @AttributeValue=@Tag, @AttributeType='XML', @AttributeFormat=NULL;
            ------------------------ End: Tag ------------------------
 
            --Call chain 1: Say procedure A calls procedure B, B calls C and so on...as part of Batch process 1
            --Call chain 2: As part of Batch process 2, procedure Z could call procedure B, B calls C and so on...the same chain..
            --However the context is different for both call chains. Different context info should be set for each chain..
            --All log entries made as part of Chain 1 will have the same AppContextInfo in Log
            --...and all log entries made as part of Chain 2 will have a different AppContextInfo in Log even for steps that are common for both chains!
 
            --Pass the tag along to all called procedures...so that log entries will have associated information recorded...and it will be querable later
            --EXEC #LoggingTestProc @CallerTag = @Tag, @CallerProcId = @@PROCID;
 
            --Can forego passing tag and calling proc info and it will be inferred since we SetAttributes for Log.Tag and Log.ParentObjectId
            --      but the ParentObjectId will be this top level procedure for all called procedures in the call tree but it works!
            EXEC #LoggingTestProc

			--This procedure has no logging framework references like @Tag or @ParentObjectId..yet the framework detects that and fills in!
			EXEC #LoggingTestProcBare
        END
        GO



 
        -------------------------------------------------------------------------------------------------------------
 
        IF object_id('TEMPDB.DBO.#LoggingTestProc') IS NOT NULL
            DROP PROCEDURE #LoggingTestProc;
        GO
 
        CREATE PROCEDURE #LoggingTestProc
        (
            @CallerTag VARCHAR(512) = NULL,
            @CallerProcId BIGINT = NULL
        )
        AS
        BEGIN
 
            ------------------------ Begin: Logging related ------------------------
            DECLARE @DBId BIGINT = DB_ID();
            DECLARE @ObjId BIGINT = @@PROCID
            DECLARE @ParentObjId BIGINT = @CallerProcId     --Set to NULL if no @CallerProcId parameter
            DECLARE @LogId BIGINT;
            DECLARE @Msg VARCHAR(255);
            DECLARE @StepLogId BIGINT;
            DECLARE @StepMsg VARCHAR(255);
            DECLARE @Tag VARCHAR(512) = @CallerTag;         --Set to NULL if no @CallerTag parameter
            ------------------------ End: Logging related ------------------------
 
            BEGIN TRY
                SET @Msg = 'Starting procedure that calculates distance to moon!'
                EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'PROCEDURE', @AdditionalInfo = @Msg, @LogId = @LogId OUTPUT        --Log procedure start
 
                ---------------
                ----STEP 1 ----
                ---------------
                --Do something that produces an error
                BEGIN TRY
                    SET @StepMsg = 'Finding the center of gravity on moon'
                    EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT       --Log step start
 
                    DECLARE @Test INT = 1/0;
 
                    EXEC EndLog @LogID = @StepLogId;    --Log step end
                END TRY
                BEGIN CATCH
                    --Error message is automatically captured in the record for current @StepLogId
                    EXEC EndLog @LogID = @StepLogId;
                END CATCH;
 
                ---------------
                ----STEP 2 ----
                ---------------
                --Do something that completes fine - run dynamic SQL
 
                DECLARE @SQL NVARCHAR(255) = 'select top 1 * from sys.tables'
 
                SET @StepMsg = @SQL
                EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'SQL', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT        --Log step start
 
                --Pretend that the SQL takes 4 seconds to run
                WAITFOR DELAY '00:00:04';
                --EXEC sp_executesql @SQL
 
                EXEC EndLog @LogID = @StepLogId;    --Log step end
 
                ---------------
                ----STEP 3 ----
                ---------------
                --Unhandled error in this step
 
                SET @StepMsg = @SQL
                EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @LogType = 'SQL', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT        --Log step start
 
                -- RAISERROR with severity 11-19 will cause execution to jump to the CATCH block.
                RAISERROR ('Moon stuff is too complex! Giving up.', -- Message text.
                           16, -- Severity.
                           1 -- State.
                           );
 
                EXEC EndLog @LogID = @StepLogId;    --Log step end
 
                EXEC EndLog @LogID = @LogId;        --Log procedure end
 
            END TRY
            BEGIN CATCH
                --Log the error to the procedure log
                IF (@LogId IS NOT NULL)
                    EXEC EndLog @LogId = @LogId;        --Log procedure end
                IF (@StepLogId IS NOT NULL)
                    EXEC EndLog @LogId = @StepLogId;    --Log step end
 
                --Comment/uncomment the version of "Rethrow" based on the version of SQL Server you are using
 
                --Rethrow: SQL Server versions below 2012
                --Get the details of the error--that invoked the CATCH block
                DECLARE
                    @ErMessage NVARCHAR(2048),
                    @ErSeverity INT,
                    @ErState INT
                SELECT
                    @ErMessage = ERROR_MESSAGE(),
                    @ErSeverity = ERROR_SEVERITY(),
                    @ErState = ERROR_STATE();
 
                --Should be able to replace with a single THROW statement in SQL 2012
                RAISERROR (@ErMessage, @ErSeverity, @ErState );
 
                --Rethrow: SQL Server versions 2012 and above
                --THROW;
 
            END CATCH;
        END;
        GO
 




 
        IF object_id('TEMPDB.DBO.#LoggingTestProcBare') IS NOT NULL
            DROP PROCEDURE #LoggingTestProcBare;
        GO
 
        CREATE PROCEDURE #LoggingTestProcBare
        AS
        BEGIN
            ------------------------ Begin: Logging related ------------------------
            DECLARE @DBId BIGINT = DB_ID();
            DECLARE @ObjId BIGINT = @@PROCID
            DECLARE @ParentObjId BIGINT = NULL;				--Set to NULL if no @CallerProcId parameter
            DECLARE @LogId BIGINT;
            DECLARE @Msg VARCHAR(255);
            DECLARE @StepLogId BIGINT;
            DECLARE @StepMsg VARCHAR(255);
            DECLARE @Tag VARCHAR(512) = NULL;				--Set to NULL if no @CallerTag parameter
            ------------------------ End: Logging related ------------------------
 
            
            SET @Msg = 'Starting procedure that has no Logging related reference variables!'
            EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @Msg, @LogId = @LogId OUTPUT        --Log procedure start

			--Does something with no reference to @Tag or @ParentObjectId
			WAITFOR DELAY '00:00:03'		-- wait for 3 seconds

			EXEC EndLog @LogId = @LogId;
		END;



        -------------------------------------------------------------------------------------------------------------
 
        --Test call...
        EXEC #MainProc
 
        --Select from the log to show what was logged
        SELECT * FROM Log ORDER BY 1 DESC
 
	
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 


 --Notice the following
 --1) We got PRINT output for our steps
 --2) Even entries for the #LoggingTestProcBare have Tag and ParentObjectId columns filled in...
 --3) The error "Moon stuff is too complex! Giving up." as automatically recorded with Error status
 --4) ObjectName and ParentObjectName are filled
 --5) LogType clearly identifies the type of log entry
 --6) AppContextInfo which was registered once got carried through procedure calls automatically
 --7) Overall procedure time as well as the individual step times are recorded
 --		Two separate @LogId and @StepLogId variables...

 --All of these can be turned on or off or controlled at application level or by [DEFAULT]

 --Logging.LogAppMaster entries control that..



		--Note down the latest LogId entry value...ane let us run all this inside a transaction that gets rolled back!

		BEGIN TRANSACTION

		EXEC #MainProc
		
		ROLLBACK;



        --Select from the log to show what was logged
        SELECT * FROM Log ORDER BY 1 DESC
 

		--Notice that we still have the logs even through we ran the whole procedure with a txn that was rolled back


 		DROP PROCEDURE #LoggingTestProcBare;
        DROP PROCEDURE #LoggingTestProc;
        DROP PROCEDURE #MainProc;
 



 
WAITFOR DELAY '00:01'		-- wait for 1 minute
GO



SELECT * FROM Logging.LogAppMaster

------------------------------------------------------------------------------------------------------

--Turn off logging by default
UPDATE Logging.LogAppMaster
SET IsOn = 0
WHERE AppContextInfo = '[DEFAULT]';
GO

--What is our latest log entry now?
SELECT MAX(LogId) AS MaxLogId
FROM Logging.Log;


--Try to log something
DECLARE @LogId BIGINT;
DECLARE @Msg VARCHAR(255) = 'Process customer records';
EXEC StartLog @ObjectID = @@PROCID, @AdditionalInfo = @Msg, @LogId = @LogId OUTPUT;     
 


--What is our latest log entry now?
SELECT MAX(LogId) AS MaxLogId
FROM Logging.Log;



--No change in logs now! 





--Update back to 1 
UPDATE Logging.LogAppMaster
SET IsOn = 1
WHERE AppContextInfo = '[DEFAULT]';








------------------------------------------------------------------------------------------------------


--Controlling settings at application level


-- Setting specific settings for application 'My Test Application'
-- Turn off logging...

INSERT INTO [Logging].[LogAppMaster]
           ([AppContextInfo]
           ,[IsOn]
           ,[LogAutonomously]
           ,[InferTag]
           ,[InferParentObjectId]
           ,[InferLastSQL]
           ,[InferError]
           ,[PrintMessages])
     VALUES
           ('My Test Application'
           ,0
           ,1
           ,1
           ,1
           ,1
           ,1
           ,1)
GO





--What is our latest log entry now?
SELECT MAX(LogId) AS MaxLogId
FROM Logging.Log;


    DECLARE @AppContextInfo VARBINARY(128) =  CAST('My Test Application' AS  VARBINARY(128))
 
    --This information will be associated with the session and will be accessible in SQL Server system views
    SET CONTEXT_INFO @AppContextInfo       

	

	--Try to log something
	DECLARE @LogId BIGINT;
	DECLARE @Msg VARCHAR(255) = 'Process customer records';
	EXEC StartLog @ObjectID = @@PROCID, @AdditionalInfo = @Msg, @LogId = @LogId OUTPUT;     
 


--What is our latest log entry now?
SELECT MAX(LogId) AS MaxLogId
FROM Logging.Log;


--No entries were made because the IsOn = 0 for application 'My Test Application'


 
WAITFOR DELAY '00:01'		-- wait for 1 minute
GO


-------------------------------------------------------------------------------------------------------------------


--Reset the context so that it will default to [DEFAULT] and log again


SET CONTEXT_INFO 0x




--What is our latest log entry now?
SELECT MAX(LogId) AS MaxLogId
FROM Logging.Log;



	--Try to log something
	DECLARE @LogId BIGINT;
	DECLARE @Msg VARCHAR(255) = 'Process customer records';
	EXEC StartLog @ObjectID = @@PROCID, @AdditionalInfo = @Msg, @LogId = @LogId OUTPUT;     
 


--What is our latest log entry now?
SELECT MAX(LogId) AS MaxLogId
FROM Logging.Log;




--We have a new entry as expected...




 
WAITFOR DELAY '00:01'		-- wait for 1 minute
GO

-------------------------------------------------------------------------------------------------------------------



--Capturing the LastSQL executed (Really DBCC INPUT_BUFFER) 





--Update IsOn back to 1 for 'My Test Application'
--	Also capture LastSQL

UPDATE Logging.LogAppMaster
SET IsOn = 1,
	InferLastSQL = 1
WHERE AppContextInfo = 'My Test Application';
GO



    DECLARE @AppContextInfo VARBINARY(128) =  CAST('My Test Application' AS  VARBINARY(128))
 
    --This information will be associated with the session and will be accessible in SQL Server system views
    SET CONTEXT_INFO @AppContextInfo       

	

	--Try to log something
	DECLARE @LogId BIGINT;
	DECLARE @Msg VARCHAR(255) = 'Process customer records';
	EXEC StartLog @ObjectID = @@PROCID, @AdditionalInfo = @Msg, @LogId = @LogId OUTPUT;     
 

 SELECT LastSQL, * FROM Logging.Log ORDER BY LogId DESC;


 --Notice that we captured the LastSQL ran in the log + we turned back on logging for this specific app!


 
 
WAITFOR DELAY '00:01'		-- wait for 1 minute
GO

-------------------------------------------------------------------------------------------------------------------
