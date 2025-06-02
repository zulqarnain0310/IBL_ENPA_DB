SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[InvestmentBalanceDetail_Sel]
--DECLARE 


@Timekey INT = 25274
		,@Mode INT =0
		,@ParentColumnvale INT =71
		,@BaseColumnvalue INT = 0
		,@flag  VARCHAR(10)=''

AS
SET DATEFORMAT DMY
DROP TABLE IF EXISTS #Balance
SELECT   A.InvestmentBalanceEntityID BaseColumn
                  , A.CurrCode
                   ,A.CurrConvRt
                   ,A.CurrPrice
                   ,A.TotalProvision        
				   ,Convert( varchar(10), A.CurrQtrdt,103) CurrQtrdt
				   ,A.Value
				   ,A.UnitHeld 
				   ,ISNULL(A.AuthorisationStatus,'A') as AuthorisationStatus
					,ISNULL(A.ModifiedBy,A.CreatedBy) CrModApBy
					,CAST(A.D2Ktimestamp AS INT)D2Ktimestamp
					,ChangeFields
					,'N' IsMainTable
INTO #Balance
FROM 

InvestmentBalanceDetail_MOD A
INNER JOIN 
(
SELECT InstrumentEntityID
			,InvestmentBalanceEntityID
			,MAX(EntityKey)EntityKey
 FROM InvestmentBalanceDetail_MOD
WHERE  EffectiveToTimeKey >= EffectiveFromTimeKey
AND   AuthorisationStatus in('NP','MP','DP','RM')
AND InstrumentEntityID = @ParentColumnvale
AND InvestmentBalanceEntityID = CASE WHEN ISNULL(@BaseColumnvalue,0)=0 THEN InvestmentBalanceEntityID ELSE @BaseColumnvalue END
GROUP BY InstrumentEntityID
			,InvestmentBalanceEntityID

)B
ON A.EntityKey = B.EntityKey



IF @Mode<>16
BEGIN
	INSERT INTO #Balance
	SELECT            A.InvestmentBalanceEntityID BaseColumn
	                  , A.CurrCode
	                   ,A.CurrConvRt
	                   ,A.CurrPrice
	                   ,A.TotalProvision        
					   ,Convert( varchar(10), A.CurrQtrdt,103) CurrQtrdt
					   ,A.Value
					   ,A.UnitHeld 
					    ,ISNULL(A.AuthorisationStatus,'A') as AuthorisationStatus
			   ,ISNULL(A.ModifiedBy,A.CreatedBy) CrModApBy
			   ,CAST(A.D2Ktimestamp AS INT)D2Ktimestamp
			   ,NULL ChangeFields
			   ,'Y' IsMainTable 
	FROM InvestmentBalanceDetail A
	WHERE EffectiveToTimeKey >= EffectiveFromTimeKey
	AND InstrumentEntityID = @ParentColumnvale
	AND InvestmentBalanceEntityID = CASE WHEN ISNULL(@BaseColumnvalue,0)=0 THEN InvestmentBalanceEntityID ELSE @BaseColumnvalue END
	AND ISNULL(AuthorisationStatus,'A')='A'

END



	IF 	@Mode=16
	BEGIN
		SELECT CASE WHEN @Flag = 'Select' THEN 'SelectData' ELSE  'GridData' END AS TableName,
				BaseColumn	
				,CurrCode	
				,CurrConvRt	
				,CurrPrice	
				,TotalProvision	
				--,CurrQtrdt	
				,CASE WHEN @Flag = 'Select' THEN CAST(CAST(CurrQtrdt AS DATE) AS VARCHAR(20))	ELSE CurrQtrdt END CurrQtrdt
				,Value	
				,UnitHeld
				,AuthorisationStatus
				,CrModApBy
				,D2Ktimestamp
				,ChangeFields
				,IsMainTable
		 FROM #Balance  WHERE IsMainTable='N'
	END
	ELSE
	BEGIN
		
		SELECT CASE WHEN @Flag = 'Select' THEN 'SelectData' ELSE  'GridData' END AS TableName,
		
		 BaseColumn	
				,CurrCode	
				,CurrConvRt	
				,CurrPrice	
				,TotalProvision	
				--,CurrQtrdt
				,CASE WHEN @Flag = 'Select' THEN CAST(CAST(CurrQtrdt AS DATE) AS VARCHAR(20))	ELSE CurrQtrdt END CurrQtrdt
				,Value	
				,UnitHeld 
				,AuthorisationStatus
				,CrModApBy
				,D2Ktimestamp
				,ChangeFields
				,IsMainTable
		FROM #Balance
	END	

GO