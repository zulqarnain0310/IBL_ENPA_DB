SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

Create PROC [dbo].[ProvisionPolicyCheckerView]
	@MenuID INT=2026,  
	@UserLoginId  VARCHAR(20)='FnaAdmin',  
	@Timekey INT=49999,
	@UploadID as Int

WITH RECOMPILE  
AS 

BEGIN

BEGIN TRY  
     
	 SET DATEFORMAT DMY

	 SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus='C') 
	 PRINT @Timekey  

  IF (@MenuID=2026)

  BEGIN
		Select 
			COUNT(Source_Alt_Key) AS COUNT
		
		From DIMPROVISIONPOLICY_mod Where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
									And UploadID=@UploadID
									AND IsUpload='Y'
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