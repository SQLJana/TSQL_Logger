--By: Jana Sattainathan [Twitter: @SQLJana] [Blog: sqljana.wordpress.com]
--________________________________________________________________________
USE Util
GO


---------------------------------------------------------------------------------------------------------------
--Demo 2 - ContextInfo
---------------------------------------------------------------------------------------------------------------

--How is this used...

--Used to tie everything a connection does from the perspective of 
--  1) DMV's
--  2) Our log entries (AppContextInfo) column
--  3) Allow common procedures to have different context's yet record the right one for run
--		i.e., "CommonProcA"	might run in context "App 1" and "App 2" and so on!

--Syntax
/*
SET CONTEXT_INFO { binary_str | @binary_var }  



Visible in DMV's

sys.dm_exec_requests
sys.dm_exec_sessions
sys.sysprocesses
*/



SET CONTEXT_INFO 0x01010101;  
GO  

SELECT context_info   
FROM sys.dm_exec_sessions  
WHERE session_id = @@SPID;  
GO  



--SET CONTEXT_INFO only deals with binary strings..but we don't!
--We need to convert from binary to meanigful value


SELECT CAST('My Fancy Application' AS VARBINARY(128))
SET CONTEXT_INFO 0x4D792046616E6379204170706C69636174696F6E

SELECT CONTEXT_INFO()

SELECT CAST(CONTEXT_INFO() AS VARCHAR(128))


SELECT context_info   
FROM sys.dm_exec_sessions  
WHERE session_id = @@SPID;  
GO  


--Unless cleared...this "Context_Info" will remain set for the duration of the session

--Typically set in top-level entry point procedure and not altered..
--...although people use it in interesting ways that is not recommended



--SQL Server 2016 has SESSION_CONTEXT - use that for arbitrary value sharing

--This framework implements SetAttribute, GetAttrribute, DeleteAttribute which does the same!


 
WAITFOR DELAY '00:01'		-- wait for 1 minute
GO




------------------------------------------------------------------------------------------------------




---------------
--Example 2
---------------
--In this example, we set context info once at the beginning of the session and use that to tie all log entries...
--      This context info, could be different for the same procedure for calls made from different applications!! That is the beauty of this.
--      The context info can also be changed mid-way through a process if that is the requirement!
 
DECLARE @LogId BIGINT;
DECLARE @AppContextInfo VARBINARY(128) =  CAST('Nightly Customer Batch' AS  VARBINARY(128))
DECLARE @Msg VARCHAR(255) = 'Process customer records';
 
SET CONTEXT_INFO @AppContextInfo
 
--Register start
EXEC StartLog @ObjectID = @@PROCID, @AdditionalInfo = @Msg, @LogId = @LogId OUTPUT;     
 


--Take a look that log entry's AppContextInfo column!
SELECT AppContextInfo, AdditionalInfo, * FROM Log WHERE LogId = @LogId;



---....but wait, we did not do anything other than setting the context 
--		the framework detected the context and recorded it for us! 





--Take a look at the other entries...they dont have a context!

SELECT AppContextInfo, AdditionalInfo, * FROM Log ORDER BY 1 DESC


WAITFOR DELAY '00:01'		-- wait for 1 minute
GO


------------------------------------------------------------------------------------------------------

