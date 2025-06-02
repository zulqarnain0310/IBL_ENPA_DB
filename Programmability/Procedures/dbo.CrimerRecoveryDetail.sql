SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


-- =============================================
-- Author:		<HAMID>
-- Create date: <09 MAR 2018>
-- Description:	<TO GET A Crime Recovery Details>
-- =============================================
--EXEC CrimerRecoveryDetail 49999, 1
CREATE PROC [dbo].[CrimerRecoveryDetail]
			 @TimeKey INT 	
			,@Mode TINYINT
	--DECLARE @TimeKey INT = 49999, @Mode TINYINT =1 
AS
	DROP TABLE IF EXISTS #CrimerRecoveryDetails
	SELECT   A.CrimeEntityId
								,A.CrimeRecEntityId
								,ParameterName StatusAlt_Key
								,CONVERT(VARCHAR(10),StatusDate,103) StatusDate
								,RecoverAmt
								,Remarks 
								,'N' IsMainTable
								INTO #CrimerRecoveryDetails
	FROM CrimerRecoveryDetails_MOD A
	INNER JOIN 
	(
		SELECT CrimeEntityId, CrimeRecEntityId, MAX(Entitykey)Entitykey
		FROM CrimerRecoveryDetails_MOD
		WHERE (EffectiveFromTimeKey <= @TimeKey AND EffectiveToTimeKey >= @TimeKey)
		AND AuthorisationStatus IN('NP','MP','DP','RM')
		GROUP BY CrimeEntityId, CrimeRecEntityId
	)B
	ON A.Entitykey = B.Entitykey
	LEFT OUTER JOIN DimParameter P
		ON  (P.EffectiveFromTimeKey <= @TimeKey AND P.EffectiveToTimeKey >= @TimeKey)
		AND DimParameterName = 'DimCrimeStatus'
		AND P.ParameterAlt_Key = A.StatusAlt_Key

	IF @Mode<>16
	BEGIN
		INSERT INTO #CrimerRecoveryDetails
		SELECT   CrimeEntityId
				,CrimeRecEntityId
				,ParameterName StatusAlt_Key
				,CONVERT(VARCHAR(10),StatusDate,103) StatusDate
				,RecoverAmt
				,Remarks 
				,'Y' IsMainTable
		FROM CrimerRecoveryDetails A
		LEFT OUTER JOIN DimParameter P
		ON  (P.EffectiveFromTimeKey <= @TimeKey AND P.EffectiveToTimeKey >= @TimeKey)
		AND (A.EffectiveFromTimeKey <= @TimeKey AND A.EffectiveToTimeKey >= @TimeKey)
		AND DimParameterName = 'DimCrimeStatus'
		AND ISNULL(A.AuthorisationStatus,'A')='A'
		AND P.ParameterAlt_Key = A.StatusAlt_Key
		--WHERE (EffectiveFromTimeKey <= @TimeKey AND EffectiveToTimeKey >= @TimeKey)
		--AND ISNULL(AuthorisationStatus,'A')='A'
	END

	IF 	@Mode=16
	BEGIN
		SELECT * FROM #CrimerRecoveryDetails  WHERE IsMainTable='N'
	END
	ELSE
	BEGIN
		SELECT * FROM #CrimerRecoveryDetails
	END	
GO