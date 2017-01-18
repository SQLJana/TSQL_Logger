
--This shows two procedures
-- usp_Main - Main entry point procedure that acts as the initial starting point for the batch
-- usp_LoadNoDBBackupFact - One of the procedures that gets called from usp_Main

--These two examples are typical of top level and called procedures off of which you can sample your code!


-- =============================================
-- Author:           Jana Sattainathan
-- Create date: Oct 05, 2016
-- Description:      Loads the Backups.DBBackupFact, Backups.DBBackupDailyFact, Backups.NoDBBackupFact, Backups.NoDBBackupDailyFact etc with data from Stage area.
-- Examples:
--            EXEC Backups.usp_Main
--
-- =============================================
CREATE PROCEDURE [Backups].[usp_Main]
              ( 
                     ---------- Begin: Logging related -------------
                     @CallerTag VARCHAR(512) = NULL,
                     @CallerProcId BIGINT = NULL
                     ---------- End: Logging related ---------------
              ) 
AS
BEGIN
       ------------------------ Begin: Logging related ------------------------
       DECLARE @DBId BIGINT = DB_ID();
       DECLARE @ObjId BIGINT = @@PROCID
       DECLARE @ParentObjId BIGINT = @CallerProcId            --Set to NULL if no @CallerProcId parameter
       DECLARE @LogId BIGINT;
       DECLARE @Msg VARCHAR(255);
       DECLARE @StepLogId BIGINT;
       DECLARE @StepMsg VARCHAR(255);
       DECLARE @Tag VARCHAR(512) = @CallerTag;                --Set to NULL if no @CallerTag parameter
       ------------------------ End: Logging related ------------------------
 
       ------------------------ Begin: Logging related ------------------------
       --Setting context for application (Do this only once in the entry-point procedure for the whole application/batch)
       --     ***** W A R N I N G *****: DO NOT SET THIS IN EVERY PROCEDURE!!
 
       DECLARE @AppContextInfo VARBINARY(128) =  CAST('Probe - Load Backup Data' AS  VARBINARY(128))
 
       --This information will be associated with the session and will be accessible in SQL Server system views
       SET CONTEXT_INFO @AppContextInfo        
 
       SET @Tag = '<Probe> ' +
                                  '<ProcessName>Populate Backups Schema Tables</ProcessName>' +
                                  '<RunNumber><<RUNNUMBER>></RunNumber>' +
                                  '<ProcessDate><<PROCESSDATE>></ProcessDate>' +
                           '</Probe>';         
       SET @CallerProcId = @@PROCID;
 
       EXEC Logging.SetAttribute @AttributeName='Log.ParentObjectId', @AttributeValue=@CallerProcId, @AttributeType='BIGINT', @AttributeFormat=NULL;
       ------------------------ End: Logging related ------------------------
 
 
       ------------------------ Begin: Tag ------------------------ 
       --Replace placeholders in the Tag
       SET @Tag = REPLACE(@Tag, '<<PROCESSDATE>>', CONVERT(VARCHAR,getdate()));
       SET @Tag = REPLACE(@Tag, '<<RUNNUMBER>>', NEXT VALUE FOR Backups.BackupsRunNumberSeq);          --Pre-defined sequence object
      
       EXEC Logging.SetAttribute @AttributeName='Log.Tag', @AttributeValue=@Tag, @AttributeType='XML', @AttributeFormat=NULL;
       ------------------------ End: Tag ------------------------
 
       BEGIN TRY
 
              ------------------------------------------------------------
              SET @Msg = 'Starting procedure!'
              ------------------------------------------------------------
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'FUNCTION', @AdditionalInfo = @Msg, @LogId = @LogId OUTPUT             --Log procedure start
 
              -- SET NOCOUNT ON added to prevent extra result sets from
              -- interfering with SELECT statements.
              SET NOCOUNT ON;
 
              ------------------------------------------------------------
              SET @StepMsg = 'Backups.DBBackupFact - Load Oracle DB Backups';
              ------------------------------------------------------------
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT         --Log step start
 
              EXEC Backups.usp_LoadDBBackupFact
                                  @DatabaseType = 'Oracle';
 
              EXEC EndLog @LogID = @StepLogId;  --Log step end
 
              ------------------------------------------------------------
              SET @StepMsg = 'Update statistics after Backups.DBBackupFact - Load Oracle';
              ------------------------------------------------------------
                          
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT         --Log step start
              EXEC sp_updatestats
              EXEC EndLog @LogID = @StepLogId;  --Log step end
 
              ------------------------------------------------------------
              SET @StepMsg = 'Backups.DBBackupFact - Load SQL Server DB Backups';
              ------------------------------------------------------------
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT         --Log step start
 
              EXEC Backups.usp_LoadDBBackupFact
                                  @DatabaseType = 'SQL Server';
 
              EXEC EndLog @LogID = @StepLogId;  --Log step end
 
              ------------------------------------------------------------
              SET @StepMsg = 'Update statistics after Backups.DBBackupFact - Load SQL Server';
              ------------------------------------------------------------
                          
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT         --Log step start
              EXEC sp_updatestats
              EXEC EndLog @LogID = @StepLogId;  --Log step end
 
 
              ------------------------------------------------------------
              SET @StepMsg = 'Backups.DBBackupFact - Load Sybase DB Backups';
              ------------------------------------------------------------
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT         --Log step start
 
              EXEC Backups.usp_LoadDBBackupFact
                                  @DatabaseType = 'Sybase';
 
              EXEC EndLog @LogID = @StepLogId;  --Log step end
 
              ------------------------------------------------------------
              SET @StepMsg = 'Update statistics after Backups.DBBackupFact - Load Sybase';
              ------------------------------------------------------------
                          
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT         --Log step start
              EXEC sp_updatestats
              EXEC EndLog @LogID = @StepLogId;  --Log step end
 
 
              ------------------------------------------------------------
              SET @StepMsg = 'Backups.DBBackupDailyFact - Load for Oracle, SQL Server and Sybase';
              ------------------------------------------------------------
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT         --Log step start
 
              EXEC Backups.usp_LoadDBBackupDailyFact;
             
              EXEC EndLog @LogID = @StepLogId;  --Log step end
 
              ------------------------------------------------------------
              SET @StepMsg = 'Update statistics after Backups.DBBackupDailyFact - Load';
              ------------------------------------------------------------
                          
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT         --Log step start
              EXEC sp_updatestats
              EXEC EndLog @LogID = @StepLogId;  --Log step end
 
              ------------------------------------------------------------
              SET @StepMsg = 'Repo.Core.ChildDB - Update with new ChildDBs for SQL Server and Sybase';
              ------------------------------------------------------------
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT         --Log step start
 
              EXEC Backups.usp_UpdateRepoChildDB;
 
              EXEC EndLog @LogID = @StepLogId;  --Log step end
 
              ------------------------------------------------------------
              SET @StepMsg = 'Backups.NoDBBackupFact - Load for Oracle, SQL Server and Sybase';
              ------------------------------------------------------------
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT         --Log step start
 
              EXEC Backups.usp_LoadNoDBBackupFact;
 
              EXEC EndLog @LogID = @StepLogId;  --Log step end
 
             
              SET @StepMsg = 'Backups.NoDBBackupDailyFact - Load for Oracle, SQL Server and Sybase';
              ------------------------------------------------------------
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT         --Log step start
 
              EXEC Backups.usp_LoadNoDBBackupDailyFact;
 
              EXEC EndLog @LogID = @StepLogId;  --Log step end
 
              SET @StepMsg = 'Backups.DBBackupLatestLagSnapshotFact - Load for Oracle, SQL Server and Sybase';
              ------------------------------------------------------------
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT         --Log step start
 
              EXEC Backups.usp_LoadDBBackupLatestLagSnapshotFact @DatabaseType = 'ALL'
 
              EXEC EndLog @LogID = @StepLogId;  --Log step end
 
              ------------------------------------------------------------
              SET @StepMsg = 'Update statistics after final - Load';
              ------------------------------------------------------------
                          
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'STEP', @AdditionalInfo = @StepMsg, @LogId = @StepLogId OUTPUT         --Log step start
              EXEC sp_updatestats
              EXEC EndLog @LogID = @StepLogId;  --Log step end
                    
      
              EXEC EndLog @LogID = @LogId;             --Log procedure end
 
       END TRY             
       BEGIN CATCH
              --Log the error to the procedure log
              IF (@LogId IS NOT NULL)
                     EXEC EndLog @LogId = @LogId;             --Log procedure end
              IF (@StepLogId IS NOT NULL)
                     EXEC EndLog @LogId = @StepLogId;  --Log step end
 
              /*
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
              */           
 
              --Rethrow: SQL Server versions 2012 and above
              THROW;
 
       END CATCH;
             
 
END;
 
 
GO
 
 
 
 
-- =============================================
-- Author:           Jana Sattainathan
-- Create date: Oct 05, 2016
-- Description:      Loads the Backups.DBBackupFact with data from Stage area.
-- Examples:
--            exec Backups.usp_LoadNoDBBackupFact @DatabaseType = 'Oracle'
--
-- =============================================
ALTER PROCEDURE [Backups].[usp_LoadNoDBBackupFact]
              ( 
                     @DatabaseType VARCHAR(50) = 'ALL',
                     ---------- Begin: Logging related -------------
                     @CallerTag VARCHAR(512) = NULL,
                     @CallerProcId BIGINT = NULL
                     ---------- End: Logging related ---------------
              ) 
AS
BEGIN
       ------------------------ Begin: Logging related ------------------------
       DECLARE @DBId BIGINT = DB_ID();
       DECLARE @ObjId BIGINT = @@PROCID
       DECLARE @ParentObjId BIGINT = @CallerProcId            --Set to NULL if no @CallerProcId parameter
       DECLARE @LogId BIGINT;
       DECLARE @Msg VARCHAR(255);
       DECLARE @StepLogId BIGINT;
       DECLARE @StepMsg VARCHAR(255);
       DECLARE @LoopLogId BIGINT;
       DECLARE @Tag VARCHAR(512) = @CallerTag;                --Set to NULL if no @CallerTag parameter
       ------------------------ End: Logging related ------------------------
 
       BEGIN TRY
 
              ------------------------------------------------------------
              SET @Msg = 'Starting procedure!'
              ------------------------------------------------------------
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'FUNCTION', @AdditionalInfo = @Msg, @LogId = @LogId OUTPUT             --Log procedure start
 
              -- SET NOCOUNT ON added to prevent extra result sets from
              -- interfering with SELECT statements.
              SET NOCOUNT ON;
 
 
              ------------------------------------------------------------
              SET @StepMsg = 'Insert into Backups.NoDBBackupFact'
              ------------------------------------------------------------
              EXEC StartLog @DatabaseId = @DBId, @Tag = @Tag, @ObjectID = @ObjId, @ParentObjectId = @ParentObjId, @LogType = 'LOOP', @AdditionalInfo = @StepMsg, @LogId = @LoopLogId OUTPUT         --Log step start
 
 
              INSERT INTO [Backups].[NoDBBackupFact]
				   (NoDBBackupFactAltKey
				   ,ProbeTargetRunId
				   ,ProbeRunId
				   ,SnapshotAgentTime
				   ,SnapshotHostTime
				   ,InstanceName
				   ,DatabaseType
				   ,DatabaseName
				   ,ChildDatabaseName)
              SELECT
                     NoDBBackupFactAltKey
				   ,ProbeTargetRunId
				   ,ProbeRunId
				   ,SnapshotAgentTime
				   ,SnapshotHostTime
				   ,InstanceName
				   ,DatabaseType
				   ,DatabaseName
				   ,ChildDatabaseName
              FROM
                     Backups.NoBackupsFactAllDBsView vw
              WHERE
                     vw.DatabaseTypeForViewPerf = CASE
                                                       WHEN @DatabaseType = 'ALL'
                                                              THEN DatabaseTypeForViewPerf
                                                       ELSE @DatabaseType
                                                END
                     AND vw.GroupRank = 1;
;
 
                    
              EXEC EndLog @LogID = @StepLogId;  --Log step end
      
              EXEC EndLog @LogID = @LogId;             --Log procedure end
 
       END TRY             
       BEGIN CATCH
              --Log the error to the procedure log
              IF (@LogId IS NOT NULL)
                     EXEC EndLog @LogId = @LogId;             --Log procedure end
              IF (@StepLogId IS NOT NULL)
                     EXEC EndLog @LogId = @StepLogId;  --Log step end
 
              /*
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
              */           
 
              --Rethrow: SQL Server versions 2012 and above
              THROW;
 
       END CATCH;
             
 
END;