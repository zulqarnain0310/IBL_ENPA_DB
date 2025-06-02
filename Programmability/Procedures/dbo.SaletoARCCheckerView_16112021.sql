SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[SaletoARCCheckerView_16112021]

@MenuID INT=10,  
@UserLoginId  VARCHAR(20)='FnaAdmin',  
@Timekey INT=49999,
@UploadID as Int
WITH RECOMPILE  
AS 
--DECLARE
--	@MenuID INT=98,  
--	@UserLoginId  VARCHAR(20)='npachecker',
--	@Timekey INT=24927,
--	@UploadID  INT=64

BEGIN

BEGIN TRY  

     
	 SET DATEFORMAT DMY

 
 Select   @Timekey=Max(Timekey) from sysDayMatrix where Cast(date as Date)=cast(getdate() as Date)

  PRINT @Timekey  

  IF (@MenuID='98')

  BEGIN
		--Select 
		----Row_Number() over(order by PoolID) as SrNo ,
		-- UploadID
		----,SummaryID
		--,NoofAccounts
		--,TotalPOSinRs
		--,TotalInttReceivableinRs
		--,TotaloutstandingBalanceinRs
		--,Convert(varchar(10),DateOfSaletoARC,103)DateOfSaletoARC
		----,Convert(varchar(20),DateOfApproval,103)DateOfApproval
		
		
		--from (
		
		--Select 
		--UploadID
		----,SummaryID
		--,NoofAccounts
		--,TotalPOSinRs
		--,TotalInttReceivableinRs
		--,TotaloutstandingBalanceinRs
		--,DateOfSaletoARC
		--From
		--SaletoARCSummary_stg Where UploadID=@UploadID --Isnull(AuthorisationStatus,'A') in ('NP','MP') And
		---- EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey
		----And UploadID=@UploadID
		----Group By 
		----PoolID,PoolName,PoolType
		--)A

		SELECT 
				UploadId
				,COUNT(*) as NoofAccounts
				,sum(BalanceOutstanding) AS TotaloutstandingBalanceinRs
				,sum(POS) AS TotalPOSinRs
				,sum(InterestReceivable) AS TotalInttReceivableinRs
		
		 from SaletoARC_Mod A
			where A.UploadId=@UploadID
			AND  (A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY)
			GROUP BY UploadId

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