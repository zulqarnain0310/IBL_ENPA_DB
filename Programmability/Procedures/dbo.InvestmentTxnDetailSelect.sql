SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[InvestmentTxnDetailSelect]
 @MenuId SMALLINT =0
		, @Mode TINYINT =0
		, @ParentColumnValue INT  =0
		, @TimeKey INT = 49999

--DECLARE   @MenuId SMALLINT =637
--		, @Mode TINYINT =0
--		, @ParentColumnValue INT  =1
--		, @TimeKey INT = 49999
AS
BEGIN
	DROP TABLE IF EXISTS #InvestmentTxnDetail
	SELECT	'GridData' TableName
			, A.TxnEntityID BaseColumn
			,CONVERT(VARCHAR(10), AcqDt, 103)AcqDt
			,ParameterName AS AcqModeAlt_Key

			--,CASE WHEN @MenuId = 636 THEN AcqUnit 
			--CASE	WHEN @MenuId = 636 THEN 'A'
			,AcqUnit AcqUnit
			,AcqUnitPrice AcqUnitPrice
			,ExpenditurePaid 
			
			,AcqCost
			,ISNULL(A.AuthorisationStatus,'A') as AuthorisationStatus
			,ISNULL(A.ModifiedBy,A.CreatedBy) CrModApBy
			,CAST(A.D2Ktimestamp AS INT)D2Ktimestamp
			,ChangeFields
			,'N' IsMainTable
	INTO #InvestmentTxnDetail
	FROM InvestmentTxnDetail_MOD A
	INNER JOIN 
	(

	SELECT  TxnEntityID, MAX(EntityKey)EntityKey
			FROM InvestmentTxnDetail_MOD
			WHERE (EffectiveFromTimeKey <= @TimeKey AND EffectiveToTimeKey >= @TimeKey)
					AND   AuthorisationStatus in('NP','MP','DP','RM')
					AND AcqType = CASE	WHEN @MenuId = 636 THEN 'A'			
										WHEN @MenuId = 637 THEN 'S'
							      END
					AND InstrumentEntityID = @ParentColumnValue
			GROUP BY TxnEntityID
	)B
	ON A.EntityKey = B.EntityKey
	LEFT OUTER JOIN DimParameter DP
	ON DP.EffectiveFromTimeKey <= @TimeKey
	AND DP.EffectiveToTimeKey >= @TimeKey
	AND DP.DimParameterName = CASE WHEN @MenuId = 636 THEN 'DimAcquistionOfSecurity' 
									WHEN @MenuId = 637 THEN 'DimSaleSecurity'
								END
	AND A.AcqModeAlt_Key = DP.ParameterAlt_Key

	INSERT INTO #InvestmentTxnDetail
	SELECT 'GridData' TableName
			, A.TxnEntityID BaseColumn
			,CONVERT(VARCHAR(10), AcqDt, 103)AcqDt
			,ParameterName AS AcqModeAlt_Key 
			,AcqUnit AcqUnit
			,AcqUnitPrice AcqUnitPrice
			,ExpenditurePaid 
			,AcqCost
			,ISNULL(A.AuthorisationStatus,'A') as AuthorisationStatus
			,ISNULL(A.ModifiedBy,A.CreatedBy) CrModApBy
			,CAST(A.D2Ktimestamp AS INT)D2Ktimestamp
			,NULL ChangeFields
			,'Y' IsMainTable 
	FROM 
	InvestmentTxnDetail A
	LEFT OUTER JOIN DimParameter DP
	ON DP.EffectiveFromTimeKey <= @TimeKey
	AND DP.EffectiveToTimeKey >= @TimeKey
	AND DP.DimParameterName = CASE WHEN @MenuId = 636 THEN 'DimAcquistionOfSecurity' 
									WHEN @MenuId = 637 THEN 'DimSaleSecurity'
								END
	AND A.AcqModeAlt_Key = DP.ParameterAlt_Key
	WHERE (A.EffectiveFromTimeKey <= @TimeKey AND A.EffectiveToTimeKey >= @TimeKey)
	AND ISNULL(A.AuthorisationStatus,'A') = 'A'
	AND AcqType = CASE	WHEN @MenuId = 636 THEN 'A'			
						WHEN @MenuId = 637 THEN 'S'
				END
	AND InstrumentEntityID = @ParentColumnValue


	IF 	@Mode=16
	BEGIN
		SELECT * FROM #InvestmentTxnDetail  WHERE IsMainTable='N'
	END
	ELSE
	BEGIN
		SELECT * FROM #InvestmentTxnDetail
	END	
END		
GO