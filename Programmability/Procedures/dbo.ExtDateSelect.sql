SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		SONALI
-- Create date: 17/07/2018
-- Description:	FETCH EXTDATE
-- =============================================
CREATE PROCEDURE [dbo].[ExtDateSelect] 
	--DECLARE	
	 @TimeKey                       INT = NULL
	,@ExtDate	                    VARCHAR(10)=NULL
	,@OperationFlag                 TINYINT		=1
	,@UserID						VARCHAR(50)	=NULL
AS

BEGIN

DROP TABLE IF EXISTS #ExtDataMatrix
   
SELECT   
		'ExtDataMatrix' TableName 
		,CONVERT(varchar(10),A.ExtDate,103)ExtDate
		,ISNULL(A.AuthorisationStatus,'A') as AuthorisationStatus
		,ISNULL(A.ModifiedBy,A.CreatedBy) CrModApBy
		,'N' IsMainTable
		INTO #ExtDataMatrix
		FROM ExtDataMatrix_MOD A
INNER JOIN 
(
	SELECT ExtDate, MAX(Entity_Key) Entity_Key 
	FROM ExtDataMatrix_MOD
	WHERE	EffectiveFromTimeKey <= @TimeKey AND EffectiveToTimeKey >= @TimeKey
	AND		AuthorisationStatus in('NP','MP','DP','RM')
	AND		ExtDate =CASE WHEN  ISNULL(@ExtDate,'')<>'' THEN CONVERT(DATE,@ExtDate,103) ELSE ExtDate END
	GROUP BY ExtDate
)B
ON A.Entity_Key = B.Entity_Key

IF @OperationFlag not in(16,17)
BEGIN

	INSERT #ExtDataMatrix
	SELECT * FROM (
	SELECT	'ExtDataMatrix' TableName
			,CONVERT(varchar(10),A.ExtDate,103)ExtDate 
			,'A' AS AuthorisationStatus
			,ISNULL(B.ModifiedBy,B.CreatedBy)CrModApBy
			,'Y' IsMainTable 
	FROM SysDataMatrix A

	LEFT JOIN ExtDataMatrix_MOD B  ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
										AND A.ExtDate=B.ExtDate
										AND B.AuthorisationStatus='A' 
				

	WHERE A.ExtDate =(CASE WHEN  ISNULL(@ExtDate,'')<>'' THEN CONVERT(DATE,@ExtDate,103) 
					 ELSE A.ExtDate END)  and A.CurrentStatus='N')A 
	WHERE A.ExtDate NOT IN (SELECT ExtDate FROM #ExtDataMatrix)
					
END

IF @OperationFlag =16
	BEGIN
		SELECT*,'ExtDataMatrix' TableName
		FROM #ExtDataMatrix WHERE IsMainTable ='N' AND CrModApBy<>@UserID
	END
ELSE
	BEGIN
		SELECT *,'ExtDataMatrix' TableName
		FROM #ExtDataMatrix 

	END
END

GO