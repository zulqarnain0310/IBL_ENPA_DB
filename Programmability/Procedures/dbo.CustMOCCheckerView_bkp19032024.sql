SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[CustMOCCheckerView_bkp19032024]
	@MenuID INT=10,  
	@UserLoginId  VARCHAR(20)='FnaAdmin',  
	@Timekey INT=49999,
	@UploadID as Int

WITH RECOMPILE  
AS 
--DECLARE
--	@MenuID INT=97,  
--	@UserLoginId  VARCHAR(20)='IBLFM8840',
--	@Timekey INT=26084,
--	@UploadID INT=893

BEGIN

BEGIN TRY  

     
	 SET DATEFORMAT DMY

	SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus_MOC='C' and MOC_Initialised='Y') 
-- set  @Timekey=(select CAST(B.timekey as int)from SysDataMatrix A
--Inner Join SysDayMatrix B ON A.TimeKey=B.TimeKey
-- where A.CurrentStatus='C')

 --SET @Timekey =(Select LastMonthDateKey from SysDayMatrix where Timekey=@Timekey) 

  PRINT @Timekey  

  IF (@MenuID='97')

  BEGIN
		Select 
			COUNT(DISTINCT CustomerId) AS COUNT
		From
		NPA_IntegrationDetails_mod Where
		 (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
		And UploadID=@UploadID AND IsUpload='Y'
  END
End Try
BEGIN CATCH
	

	INSERT INTO dbo.Error_Log
				SELECT ERROR_LINE() as ErrorLine,ERROR_MESSAGE()ErrorMessage,ERROR_NUMBER()ErrorNumber
				,ERROR_PROCEDURE()ErrorProcedure,ERROR_SEVERITY()ErrorSeverity,ERROR_STATE()ErrorState
				,GETDATE()


END CATCH

END
  
GO