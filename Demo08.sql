--By: Jana Sattainathan [Twitter: @SQLJana] [Blog: sqljana.wordpress.com]
--________________________________________________________________________
USE salesdb
GO



--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--BEGIN: Synonyms in other Databases
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 
--Use this to create synonyms for the Logging related objects in other databases
 
--
--Table: Logging.Log
--
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'SN' AND name = 'Log')
    DROP SYNONYM Log
GO
 
CREATE SYNONYM Log FOR [Util].Logging.Log;
GO
 
--
--StoredProc: Logging.StartLog
--
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'SN' AND name = 'StartLog')
    DROP SYNONYM StartLog
GO
 
CREATE SYNONYM StartLog FOR [Util].Logging.StartLog;
GO
 
--
--StoredProc: Logging.EndLog
--
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'SN' AND name = 'EndLog')
    DROP SYNONYM EndLog
GO
 
CREATE SYNONYM EndLog FOR [Util].Logging.EndLog;
GO
 
--
--StoredProc: Logging.SetAttribute
--
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'SN' AND name = 'SetAttribute')
    DROP SYNONYM SetAttribute;
GO
 
CREATE SYNONYM SetAttribute FOR [Util].Logging.SetAttribute;
GO
 
--
--StoredProc: Logging.GetAttribute
--
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'SN' AND name = 'GetAttribute')
    DROP SYNONYM GetAttribute;
GO
 
CREATE SYNONYM GetAttribute FOR [Util].Logging.GetAttribute;
GO
 
--
--StoredProc: Logging.DeleteAttribute
--
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'SN' AND name = 'DeleteAttribute')
    DROP SYNONYM DeleteAttribute;
GO
 
CREATE SYNONYM DeleteAttribute FOR [Util].Logging.DeleteAttribute;
GO
 
--
--StoredProc: Logging.ShowAllAttributes
--
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'SN' AND name = 'ShowAllAttributes')
    DROP SYNONYM ShowAllAttributes;
GO
 
CREATE SYNONYM ShowAllAttributes FOR [Util].Logging.ShowAllAttributes;
GO
 
--
--StoredProc: Logging.DeleteAllAttributes
--
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'SN' AND name = 'DeleteAllAttributes')
    DROP SYNONYM DeleteAllAttributes;
GO
 
CREATE SYNONYM DeleteAllAttributes FOR [Util].Logging.DeleteAllAttributes;
GO




 
WAITFOR DELAY '00:01'		-- wait for 1 minute
GO




------------------------------------------------------------------------------------------------------


SELECT DB_NAME()
--We are in another DB outside the home of Logging


SELECT * FROM Log
--..and are able to access the log


-------------------- WRONG USAGE -----------------------

---We are also able to log new entries just using the Synonyms
DECLARE @LogId BIGINT;
EXEC StartLog @AdditionalInfo = 'Some status message', @LogId = @LogId OUTPUT;
PRINT @LogId

EXEC EndLog @LogId = @LogId;
SELECT * FROM Log ORDER BY LogId DESC;






--Warning: Notice that the database name is not the outside database but Util..
--			That is because the context of code evaluation is still Util.
--			The right database name must be explicitly passed in....


-------------------- RIGHT USAGE -----------------------
DECLARE @LogId BIGINT;
DECLARE @DatabaseId BIGINT = DB_ID();
 
EXEC StartLog @DatabaseId = @DatabaseId, @ObjectID = @@PROCID, @LogType = 'STEP', @AdditionalInfo = 'Added DatabaseId although it was detected before!', @LogId = @LogId OUTPUT;

EXEC EndLog @LogId = @LogId;


--Now the database name is fixed!
SELECT * FROM Log ORDER BY LogId DESC;



--That was the caution for using synonyms! Mostly, it should be fine though...