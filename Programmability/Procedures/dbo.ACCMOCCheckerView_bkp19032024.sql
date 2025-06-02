SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
create PROC [dbo].[ACCMOCCheckerView_bkp19032024]

@MenuID INT=10,  
@UserLoginId  VARCHAR(20)='FnaAdmin',  
@Timekey INT=49999,
@UploadID as Int
WITH RECOMPILE  
AS 


BEGIN

BEGIN TRY  

     
	 SET DATEFORMAT DMY

	SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus_MOC='C' and MOC_Initialised='Y') 
-- set  @Timekey=(select CAST(B.timekey as int)from SysDataMatrix A
--Inner Join SysDayMatrix B ON A.TimeKey=B.TimeKey
-- where A.CurrentStatus='C')
 --SET @Timekey =(Select LastMonthDateKey from SysDayMatrix where Timekey=@Timekey) 

  PRINT @Timekey  

  IF (@MenuID='101')

  BEGIN
		--Select Row_Number() over(order by NCIF_Id) as SrNo ,* from (
		
		Select 
		
		COUNT(*) NoofAccounts
		,Sum(isnull(cast(Balance as float),0))Balance
		,Sum(isnull(cast(ApprRV as float),0))SecurityValue
		From
		NPA_IntegrationDetails_MOD Where --Isnull(AuthorisationStatus,'A') in ('NP','MP') And
		 (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
		And UploadID=@UploadID
		--Group By 
		--NCIF_Id,CustomerName,CustomerACID,LoanAgreementNo,BuyoutPartyLoanNo
		--)A

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