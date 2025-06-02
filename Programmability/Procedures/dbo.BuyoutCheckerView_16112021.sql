SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[BuyoutCheckerView_16112021]

@MenuID INT=10,  
@UserLoginId  VARCHAR(20)='FnaAdmin',  
@Timekey INT=49999,
@UploadID as Int
WITH RECOMPILE  
AS 


BEGIN

BEGIN TRY  

     
	 SET DATEFORMAT DMY

 
 set  @Timekey=(select CAST(B.timekey as int)from SysDataMatrix A
Inner Join SysDayMatrix B ON A.TimeKey=B.TimeKey
 where A.CurrentStatus='C')

  PRINT @Timekey  

  IF (@MenuID='99')

  BEGIN
		--Select Row_Number() over(order by NCIF_Id) as SrNo ,* from (
		
		Select 
		-- NCIF_Id
		--,CustomerName
		--,CustomerACID
		--,LoanAgreementNo
		--,BuyoutPartyLoanNo
		--Sum(isnull(cast(TotalNoofBuyoutParty as float),0))TotalNoofBuyoutParty
		Sum(isnull(cast(PrincipalOutstanding as float),0))TotalPrincipalOutstanding
		,Sum(isnull(cast(InterestReceivable as float),0))TotalInterestReceivable
		,Sum(isnull(cast(TotalOutstanding as float),0))GrandTotalOutstanding
		--,Sum(isnull(cast(TotalSecurityValue as float),0))TotalSecurityValue
		,COUNT(*) NoofAccounts
		
		From
		BuyoutDetails_Mod Where --Isnull(AuthorisationStatus,'A') in ('NP','MP') And
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