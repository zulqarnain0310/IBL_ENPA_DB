SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[BuyoutDownloadData_16112021]
	@Timekey INT
	,@UserLoginId VARCHAR(100)
	,@ExcelUploadId INT
	,@UploadType VARCHAR(50)
	--,@Page SMALLINT =1     
 --   ,@perPage INT = 30000   
AS

----DECLARE @Timekey INT=49999
----	,@UserLoginId VARCHAR(100)='FNASUPERADMIN'
----	,@ExcelUploadId INT=4
----	,@UploadType VARCHAR(50)='Interest reversal'

BEGIN
		SET NOCOUNT ON;

		set @Timekey=(select CAST(B.timekey as int)from SysDataMatrix A
Inner Join SysDayMatrix B ON A.TimeKey=B.TimeKey
 where A.CurrentStatus='C')
		  		  PRINT @Timekey  

		--DECLARE @PageFrom INT, @PageTo INT   
  
		--SET @PageFrom = (@perPage*@Page)-(@perPage) +1  
		--SET @PageTo = @perPage*@Page  

IF (@UploadType='Buyout Upload')

BEGIN
		PRINT 'REV'
		--SELECT * FROM(
		SELECT 'Details' as TableName
		,A.UploadID
		,A.SrNo
		,A.AsOnDate
		,A.PAN
		,A.NCIF_Id AS DedupIDUCICEnterpriseCIF
		,A.CustomerName
		,A.CustomerACID AS CustomerAccountNo
		,A.LoanAgreementNo
		,A.BuyoutPartyLoanNo AS IndusindLoanAccountNo
		,A.TotalOutstanding
		,A.InterestReceivable AS UnrealizedInterest
		,A.PrincipalOutstanding
		,B.AssetClassName AS AssetClassification 
		,A.FinalNpaDt AS NPA_Date
		,A.DPD
		,A.SecurityValue AS SecurityAmount
		,A.AdditionalProvisionAmount
		,A.AcceleratedProvisionPercentage
		,A.SecuredStatus
		,A.Action
		
		------,ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS ROW_NUM
		FROM BuyoutDetails_Mod A
		INNER JOIN DimAssetClass B
		ON A.FinalAssetClassAlt_Key=B.AssetClassAlt_Key
		WHERE A.UploadID=@ExcelUploadId
		AND A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey

		SELECT 'Summary' as TableName, Row_Number() over(order by NCIF_Id) as SrNo
		,UploadID
		,SummaryID
		,NCIF_Id AS DedupIDUCICEnterpriseCIF
		,CustomerName
		,CustomerACID AS CustomerAccountNo
		,LoanAgreementNo
		,BuyoutPartyLoanNo AS IndusindLoanAccountNo
		,TotalNoofBuyoutParty
		,TotalPrincipalOutstandinginRs
		,TotalInterestReceivableinRs AS TotalUnrealizedInterest
		,GrandTotalOutstanding
		,TotalSecurityValue AS TotalSecurityAmount
		
		------,ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS ROW_NUM
		FROM BuyoutSummary_Mod
		WHERE UploadId=@ExcelUploadId
		AND EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey

		--)A
		--WHERE ROW_NUM BETWEEN  @PageFrom AND @PageTo
		--ORDER BY ROW_NUM  

END



END
GO