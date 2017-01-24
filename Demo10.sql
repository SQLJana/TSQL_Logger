  ---------------
    --Example 10 - A complete example. See the other examples below this example for simpler, step by step understanding
    ---------------
 
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
                EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'ANONYMOUS BLOCK', @AdditionalInfo = @Msg, @LogId = @LogId OUTPUT        --Log procedure start
 
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
 
        -------------------------------------------------------------------------------------------------------------
 
        --Test call...
        EXEC #MainProc
 
        --Select from the log to show what was logged
        SELECT * FROM Log ORDER BY 1 DESC
 
        DROP PROCEDURE #LoggingTestProc;
        DROP PROCEDURE #MainProc;
 
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++