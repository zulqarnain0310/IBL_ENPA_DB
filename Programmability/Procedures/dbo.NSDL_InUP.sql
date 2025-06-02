SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[NSDL_InUP]
 @TimeKey INT
,@XmlDocument  XML
,@UserID   VARCHAR(20)
,@Result   INT  OUTPUT

AS

--DECLARE
-- @TimeKey INT
--,@XmlDocument  XML
--,@UserID   VARCHAR(20)


IF OBJECT_ID('TEMPDB..#NSDL_Details')IS NOT NULL
DROP TABLE #NSDL_Details


SELECT
  c.value('./ENTCIF[1]','INT')ENTCIF
 ,c.value('./PAN[1]','varchar(10)')PAN
 ,c.value('./NSDL_MiddleName[1]','varchar(80)')NSDL_MiddleName
 ,c.value('./NSDL_LastName[1]','varchar(80)')NSDL_LastName
 ,c.value('./NSDL_FirstName[1]','varchar(80)')NSDL_FirstName
 ,c.value('./PAN_Status[1]','char(1)')PAN_Status

 INTO #NSDL_Details
 FROM @XmlDocument.nodes('DataSet/GridData') AS t(c)

 BEGIN TRY
	BEGIN TRANSACTION
 
 select * from #NSDL_Details

		UPDATE A
		SET A.NSDL_FirstName=B.NSDL_FirstName
			,A.NSDL_MiddleName=B.NSDL_MiddleName
			,A.NSDL_LastName=B.NSDL_LastName
			,A.PAN_Status=B.PAN_Status 
			,A.ModifiedBy=@UserID
			,A.DateModified=GETDATE()
			,A.InsertFlag='Y'
		FROM PAN_MismatchDetails A
		INNER JOIN #NSDL_Details B  ON (A.TimeKey=@TimeKey)
										AND A.PAN=B.PAN
										--AND A.NCIF=B.ENTCIF

	COMMIT 	TRANSACTION
SET @Result=1	
END TRY

BEGIN CATCH
ROLLBACK TRANSACTION
		SELECT ERROR_MESSAGE() 
		RETURN -1
END CATCH
										
		

GO