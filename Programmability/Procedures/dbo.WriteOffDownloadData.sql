SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[WriteOffDownloadData]
	@Timekey INT
	,@UserLoginId VARCHAR(100)
	,@ExcelUploadId INT
	,@UploadType VARCHAR(50)
	--,@Page SMALLINT =1     
 --   ,@perPage INT = 30000   
AS
--exec WriteOffDownloadData @TimeKey=24927,@UserLoginId=N'npachecker',@ExcelUploadId=N'60',@UploadType=N'Write Off Data Upload'
--go

--DECLARE @Timekey INT=24927
--	,@UserLoginId VARCHAR(100)='npachecker'
--	,@ExcelUploadId INT=60
--	,@UploadType VARCHAR(50)='Write Off Data Upload'

BEGIN
		SET NOCOUNT ON;

		Select @Timekey=Max(Timekey) from dbo.SysDayMatrix  
		  where  Date=cast(getdate() as Date)
		  		  PRINT @Timekey  

		--DECLARE @PageFrom INT, @PageTo INT   
  
		--SET @PageFrom = (@perPage*@Page)-(@perPage) +1  
		--SET @PageTo = @perPage*@Page  

IF (@UploadType='Write Off Data Upload')

BEGIN
		PRINT 'REV'
		--SELECT * FROM(
		SELECT 'WriteOff Details' as TableName
		,A.UploadId
		,A.SrNo
		,CONVERT(VARCHAR(20),A.AsOnDate,103) AS AsOnDate
		,B.SourceName AS SourceSystemName
		,A.NCIF_Id
		,A.CustomerID
		--,CustomerName
		,A.CustomerACID AS AccountID
		,CONVERT(VARCHAR(20),A.WriteOffDt,103) AS WriteOffDate
		,A.WO_PWO AS WriteOffType
		,A.WriteOffAmt AS WriteOffAmtInterest
		,A.IntSacrifice AS WriteOffAmtPrincipal
		,A.Action
		------,ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS ROW_NUM
		FROM AdvAcWODetail_Mod A
		INNER JOIN DimSourceSystem B
		ON A.SrcSysAlt_Key=B.SourceAlt_Key
		AND (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey)
		WHERE A.UploadId=@ExcelUploadId
		AND A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey

		SELECT 'Summary' as TableName--, Row_Number() over(order by PoolID) as SrNo
		,UploadID
		--,SummaryID
		,count(CustomerID) NoofAccounts
		,sum(WriteOffAmt) TotalWriteOffAmtinRS
		,sum(IntSacrifice) TotalIntSacrificeinRS
		
		------,ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS ROW_NUM
		FROM AdvAcWODetail_Mod
		WHERE UploadId=@ExcelUploadId
		AND EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
		group by UploadID

		--)A
		--WHERE ROW_NUM BETWEEN  @PageFrom AND @PageTo
		--ORDER BY ROW_NUM  

END



END
GO