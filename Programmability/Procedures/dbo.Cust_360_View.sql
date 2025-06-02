SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[Cust_360_View]
--DECLARE
 @TimeKey INT=24927
,@SearchBy CHAR(1)='P'  ---E- ENCIF,C-customerId,P-Pan,A-Account
,@SearchID VARCHAR(MAX)='10504757'
AS

BEGIN
			DROP TABLE IF EXISTS #UCIF
			CREATE TABLE #UCIF
			(Items VARCHAR(max))

			INSERT INTO #UCIF
			SELECT * FROM split(@SearchID,',')

			DROP TABLE IF EXISTS #CTE
			CREATE TABLE #CTE (NCIF_Id VARCHAR(20))

			IF @SearchBy='E'
				BEGIN
					INSERT INTO #CTE
					SELECT  A.NCIF_Id  FROM NPA_IntegrationDetails A
					--INNER JOIN #UCIF B ON B.Items=A.NCIF_Id
					WHERE A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey
					AND @SearchBy='E' AND ISNULL(A.NCIF_Id,'')<>''
					 AND EXISTS (SELECT Items FROM #UCIF B
										  WHERE B.Items=A.NCIF_Id
										 )
				END								
			ELSE IF @SearchBy='C'
				BEGIN
					 INSERT INTO #CTE
					 SELECT  A.NCIF_Id FROM NPA_IntegrationDetails A
					 --INNER JOIN #UCIF B ON B.Items=A.CustomerId
					 WHERE A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey
					 AND @SearchBy='C'AND ISNULL(A.CustomerId,'')<>'' 
					 AND EXISTS (SELECT Items FROM #UCIF B
					 						WHERE B.Items=A.CustomerId
					 			)
				END							

			ELSE IF @SearchBy='A'
				BEGIN
					INSERT INTO #CTE
					SELECT  A.NCIF_Id FROM NPA_IntegrationDetails A
					--INNER JOIN #UCIF B ON B.Items=A.CustomerACID
					WHERE A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey
					AND @SearchBy='A'AND ISNULL(A.CustomerACID,'')<>'' 
					AND EXISTS (SELECT Items FROM #UCIF B
											WHERE B.Items=A.CustomerACID
								)
				END							
			ELSE IF @SearchBy='P'
				BEGIN
					INSERT INTO #CTE
					SELECT  A.NCIF_Id FROM NPA_IntegrationDetails A
					--INNER JOIN #UCIF B ON B.Items=A.PAN
					WHERE A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey
					AND @SearchBy='P'AND ISNULL(A.PAN,'')<>'' 
					AND EXISTS (SELECT Items FROM #UCIF B
											WHERE B.Items=A.PAN
								)
				END						

			DROP TABLE IF EXISTS #NCIF_DATA
			CREATE TABLE #NCIF_DATA(NCIF_Id varchar(20))
			INSERT INTO #NCIF_DATA(NCIF_Id)
			SELECT  NCIF_Id  FROM #CTE	gROUP BY  NCIF_Id

			SELECT  
			A.NCIF_Id AS UCIF,
			A.CustomerId,
			A.PAN,
			A.CustomerName,
			A.SrcSysAlt_Key,
			D.SourceName AS SourceSystem,
			A.CustomerACID AS AccountID,
			--A.SanctionedLimit AS LimitSanctioned,							-- Commented By SATWAJI on 19/08/2021 AS Per Banks Requirement
			A.Balance,
			A.AC_AssetClassAlt_Key,
			B.AssetClassShortName AS AssetClassification,
			--CONVERT(VARCHAR(10),A.AC_NPA_Date,103) AS NPA_Date,
			FORMAT(A.AC_NPA_Date,'dd/MM/yyyy')AS NPA_Date,
			A.NCIF_AssetClassAlt_Key,
			C.AssetClassShortName AS UCIFAssetClassification,
			FORMAT(A.NCIF_NPA_Date,'dd/MM/yyyy')AS NCIF_NPA_Date,
			--CONVERT(VARCHAR(10),A.NCIF_NPA_Date,103) AS UCIF_NPA_Date,
			FORMAT(A.NCIF_NPA_Date,'dd/MM/yyyy')AS UCIF_NPA_Date,
			A.MaxDPD AS MaxDPD
			--ISNULL(PNPA_Status,'N')AS PotentialNPA,						-- Commented By SATWAJI on 19/08/2021 AS Per Banks Requirement
			--CONVERT(VARCHAR(10),PNPA_Date,103) AS PotentialNPA_Date ,		-- Commented By SATWAJI on 19/08/2021 AS Per Banks Requirement
			--FORMAT(PNPA_Date,'dd/MM/yyyy')AS PotentialNPA_Date,
			--CASE WHEN AC_AssetClassAlt_Key<>NCIF_AssetClassAlt_Key THEN (CASE WHEN AC_AssetClassAlt_Key<>1 AND NCIF_AssetClassAlt_Key=1 THEN 'N' ELSE 'Y' END)  
			--ELSE 'N' END [Ispercolated]									-- Commented By SATWAJI on 19/08/2021 AS Per Banks Requirement
			FROM NPA_IntegrationDetails A

			INNER JOIN #NCIF_DATA		E  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
												AND A.NCIF_Id=E.NCIF_ID

			LEFT JOIN DimAssetClass     B  ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
											   AND A.AC_AssetClassAlt_Key=B.AssetClassAlt_Key
			
			LEFT JOIN DimAssetClass     C  ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
											   AND A.NCIF_AssetClassAlt_Key=C.AssetClassAlt_Key
			
			LEFT JOIN DimSourceSystem   D  ON (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
											   AND A.SrcSysAlt_Key=D.SourceAlt_Key									
							
			ORDER BY A.NCIF_Id,A.CustomerId,A.CustomerACID

			DROP TABLE IF EXISTS #CTE
			DROP TABLE IF EXISTS #UCIF
			DROP TABLE IF EXISTS #NCIF_DATA

	END			

GO