SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CustMOCDownloadData]
	@Timekey INT
	,@UserLoginId VARCHAR(100)
	,@ExcelUploadId INT
	,@UploadType VARCHAR(50)
	--,@Page SMALLINT =1     
 --   ,@perPage INT = 30000   
AS

--DECLARE @Timekey INT=26084
--	,@UserLoginId VARCHAR(100)='IBLFM8840'
--	,@ExcelUploadId INT=871
--	,@UploadType VARCHAR(50)='Customer MOC Upload'

BEGIN
		SET NOCOUNT ON;

		SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus_MOC='C' and MOC_Initialised='Y') 
--		set @Timekey=(select CAST(B.timekey as int)from SysDataMatrix A
--Inner Join SysDayMatrix B ON A.TimeKey=B.TimeKey
-- where A.CurrentStatus='C')

  --SET @Timekey =(Select LastMonthDateKey from SysDayMatrix where Timekey=@Timekey) 
		  		  PRINT @Timekey  

		--DECLARE @PageFrom INT, @PageTo INT   
  
		--SET @PageFrom = (@perPage*@Page)-(@perPage) +1  
		--SET @PageTo = @perPage*@Page  

IF (@UploadType='Customer MOC Upload')

BEGIN
		PRINT 'REV'
		SELECT *,ROW_NUMBER()Over( Order by CIFCustomerIdentifier)Srno FROM(
		SELECT DISTINCT
		'Customer MOC Details' as TableName
		,A.UploadID
		--, Row_Number() over(partition BY customerid order by customerid) as SrNo
		--,A.AsOnDate
		,A.NCIF_Id AS DedupIDUCICEnterpriseCIF
		,A.CustomerID AS CIFCustomerIdentifier
		,A.CustomerName
		,B.AssetClassShortName AS MOC_AssetClassification
		,CONVERT(VARCHAR(10),A.MOC_NPA_Date,103) AS MOC_NPADate
			--,A.MOC_SecurityValue
		,A.AddlProvisionPer AS AdditionalProvisionPercentage
		,R.MocReasonName AS MOC_Reason
		,A.MOC_Remark AS MOC_Remark
		,A.MOCTYPE AS MOC_Type
		--,A.MOC_SOURCE
		
		------,ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS ROW_NUM
		FROM NPA_IntegrationDetails_MOD A
		LEFT JOIN DimAssetClass B ON B.AssetClassAlt_Key = A.MOC_AssetClassAlt_Key
		LEFT JOIN DimMocReason  R ON R.MocReasonAlt_Key= A.MOC_ReasonAlt_Key
									AND R.MocReasonCategory='Customer Reason'
									AND R.EffectiveToTimeKey=49999
		WHERE A.UploadID=@ExcelUploadId
		AND A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey
		AND A.IsUpload='Y'
		)A 
		--Where A.SrNo=1

		
		SELECT 
		'Summary' as TableName
		, Row_Number() over(Partition By NCIF_Id order by NCIF_Id) as SrNo
		,UploadID
		--,SummaryID
		,NCIF_Id 
		,count(distinct CustomerID) NoofAccounts
		--,sum(MOC_SecurityValue) SecurityValue

		
		------,ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS ROW_NUM
		FROM NPA_IntegrationDetails_MOD
		WHERE UploadId=@ExcelUploadId
		AND EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
		AND IsUpload='Y'
		GROUP BY UploadID,NCIF_Id
		--)A
		--WHERE ROW_NUM BETWEEN  @PageFrom AND @PageTo
		--ORDER BY ROW_NUM  

END



END

--select * from AccountLvlMOCDetails_stg
GO