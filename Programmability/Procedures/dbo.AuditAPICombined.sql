SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
 
CREATE PROCEDURE [dbo].[AuditAPICombined]  
 
	   @Parameter Varchar(02)=N'',
       @PANNo VARCHAR(10) = N'',
       @NCIF_Id VARCHAR(10) = N'',
       @Aadhar  VARCHAR(2000)=N'',
	   @VoterId VARCHAR(20)=N'',  
       @TimeKey INT        = 0

AS
SET NOCOUNT ON 
--DECLARE
-- @Parameter Varchar(50)=N'',
-- @PANNo   VARCHAR(10) = N'',--CCKPR3153B  ATNPS2773C
-- @NCIF_Id VARCHAR(10) = N'10000027',--10001967  
-- @Aadhar  VARCHAR(2000)=N'',
-- @VoterId VARCHAR(20)=N'', -- SVI2339884
-- @TimeKey INT  = 26084

BEGIN
      SET @TimeKey= (Select TimeKey From SysDataMatrix WHERE CurrentStatus='C')

      PRINT @TimeKey

IF ISNULL(@Parameter,'')=''
		BEGIN	
			SELECT 'Please provide Atleast One Value in Parameter...Either 2P or 4P' As Remark            
		END

	ELSE
	
		BEGIN
			IF ISNULL(@Parameter,'')='2P'
				BEGIN
					EXEC [dbo].[AuditAPISelect] @PANNo,@NCIF_Id,@TimeKey
				END

			ELSE
				BEGIN
					EXEC [dbo].[AuditAPISelectFeature] @PANNo,@NCIF_Id,@Aadhar,@VoterId,@TimeKey
				END
		END


END
GO