--By: Jana Sattainathan [Twitter: @SQLJana] [Blog: sqljana.wordpress.com]
--________________________________________________________________________
USE Util
GO


--SQL Server 2016 has SESSION_CONTEXT to save name/value pairs persisted across the session
--	In earlier versions, us these methods provided by the framework to do so.

--Internally, Logger uses these functions to keep track of Tag, ParentObjectId etc..

---------------------------------------------------------------------------------------------------------------
--Demo 5 - Attributes
---------------------------------------------------------------------------------------------------------------
/*
Logging.SetAttribute – Save off discrete variables that are pertinent
Logging.GetAttribute – Get attributes that have been saved (even from other procs)
Logging.DeleteAttribute – Delete one saved variable
Logging.DeleteAllAttributes – Clears all saved variables
Logging.ShowAllAttributes – Display saved variables
*/


--Save a value into the session cache
Logging.SetAttribute @AttributeName='TEST', @AttributeValue='DAFSFASFSA', @AttributeType='VARCHAR', @AttributeFormat=NULL;

--Values are stored to a global Temp table
SELECT * FROM ##TempAttributesTable;	


 
WAITFOR DELAY '00:01'		-- wait for 1 minute
GO




------------------------------------------------------------------------------------------------------




    ---------------
    --Example 1 - Set and Get a simple string that happens to be XML. Need to do conversion yourself. Notice SQL_VARIANT to VARCHAR(200) conversion for @AttributeValue
    ---------------
 
        --Set some attribute in Procedure A.
        -----------------------------------
        DECLARE @Tag VARCHAR(200)= '<TestApplication> ' +
                                        '<ProcessName>Test process</ProcessName>' +
                                        '<LogId>1214</LogId>' +
                                        '<RunNumber>22</RunNumber>' +
                                    '</TestApplication>';
        EXEC Logging.SetAttribute @AttributeName='Tag', @AttributeValue=@Tag, @AttributeType='XML', @AttributeFormat=NULL;
 
        EXEC Logging.ShowAllAttributes;
 
        --Get the value of that attribute in Procedure B
        -----------------------------------
        DECLARE @AttributeName  VARCHAR(100) = 'Tag';
        DECLARE @AttributeValue SQL_VARIANT;
        DECLARE @AttributeType VARCHAR(25);
        DECLARE @AttributeFormat VARCHAR(100);
 
        EXEC Logging.GetAttribute @AttributeName='Tag', @AttributeValue=@AttributeValue OUTPUT, @AttributeType=@AttributeType OUTPUT, @AttributeFormat=@AttributeFormat OUTPUT, @IgnoreIfAttributeIsMissing=1
 
        PRINT @AttributeName;
        PRINT CONVERT(VARCHAR(200), @AttributeValue);
        PRINT @AttributeType;
        PRINT @AttributeFormat;




 
WAITFOR DELAY '00:01'		-- wait for 1 minute
GO




------------------------------------------------------------------------------------------------------




	 ---------------
    --Example 2 - Set and Get a simple string but ignore things like type, format etc that we dont care about
    ---------------
 
        --Set some attribute
        -----------------------------------
        DECLARE @Tag VARCHAR(200)= '<TestApplication> ' +
                                        '<ProcessName>Test process</ProcessName>' +
                                        '<LogId>1214</LogId>' +
                                        '<RunNumber>22</RunNumber>' +
                                    '</TestApplication>';
        EXEC Logging.SetAttribute @AttributeName='Log.Tag', @AttributeValue=@Tag, @AttributeType='XML', @AttributeFormat=NULL;
 
        EXEC Logging.ShowAllAttributes;
 
        --Get the value of that attribute in another procedure
        -----------------------------------
        DECLARE @AttributeName  VARCHAR(100) = 'Log.Tag1';
        DECLARE @AttributeValue SQL_VARIANT;
        EXEC Logging.GetAttribute @AttributeName=@AttributeName, @AttributeValue=@AttributeValue OUTPUT, @AttributeType=NULL, @AttributeFormat=NULL, @IgnoreIfAttributeIsMissing=1
 
        PRINT @AttributeName;
        PRINT CONVERT(VARCHAR(200), @AttributeValue);



 
WAITFOR DELAY '00:01'		-- wait for 1 minute
GO




------------------------------------------------------------------------------------------------------


--Example of displaying and removing attributes

	EXEC Logging.ShowAllAttributes


	EXEC Logging.DeleteAttribute @AttributeName='TEST'


	
	EXEC Logging.ShowAllAttributes



 
WAITFOR DELAY '00:01'		-- wait for 1 minute
GO




------------------------------------------------------------------------------------------------------

--Delete all attributes

		EXEC Logging.ShowAllAttributes

        EXEC Logging.DeleteAllAttributes
 
        EXEC Logging.ShowAllAttributes



WAITFOR DELAY '00:01'		-- wait for 1 minute
GO




------------------------------------------------------------------------------------------------------
