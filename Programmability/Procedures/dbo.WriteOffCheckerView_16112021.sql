SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[WriteOffCheckerView_16112021]

@MenuID INT=10,  
@UserLoginId  VARCHAR(20)='FnaAdmin',  
@Timekey INT=49999,
@UploadID as Int
WITH RECOMPILE  
AS 


BEGIN

BEGIN TRY  

     
	 SET DATEFORMAT DMY

 
 Select   @Timekey=Max(Timekey) from sysDayMatrix where Cast(date as Date)=cast(getdate() as Date)

  PRINT @Timekey  

  IF (@MenuID='96')

  BEGIN
		Select 
		--Row_Number() over(order by PoolID) as SrNo ,
		 NoofAccounts
		,TotalWriteOffAmtinRS
		,TotalIntSacrificeinRS
		
		from (
		
		Select 
		 NoofAccounts
		,TotalWriteOffAmtinRS
		,TotalIntSacrificeinRS
		From
		WriteOffSummary_Stg Where UploadID=@UploadID--Isnull(AuthorisationStatus,'A') in ('NP','MP') And
		-- EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey
		--And UploadID=@UploadID
		--Group By 
		--PoolID,PoolName,PoolType

		--BuyoutSummary_Mod Where --Isnull(AuthorisationStatus,'A') in ('NP','MP') And
		-- EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey
		--And UploadID=@UploadID
		)A

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