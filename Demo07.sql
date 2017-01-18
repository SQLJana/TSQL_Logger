--By: Jana Sattainathan [Twitter: @SQLJana] [Blog: sqljana.wordpress.com]
--________________________________________________________________________
USE Util
GO

--What sessions that are logging are active now?
SELECT * FROM [Logging].[vwActiveLoggingSessions];


--What are the latest entries in the Log from active sessions?
SELECT * FROM [Logging].[vwLogOfActiveSessionLatestEntry];


--What are the log records active sessions?
SELECT * FROM [Logging].[vwLogOfActiveSessions];


--Summary information by LogType
SELECT * FROM [Logging].[vwLogSummaryByLogType];



--Summary information by Step
SELECT * FROM [Logging].[vwLogSummaryByStep];