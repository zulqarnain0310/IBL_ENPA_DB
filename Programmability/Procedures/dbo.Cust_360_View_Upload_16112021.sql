SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
--USE [IndusInd_New]
--GO
--/****** Object:  StoredProcedure [dbo].[Cust_360_View_Upload]    Script Date: 22-11-2019 19:08:12 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
CREATE Proc [dbo].[Cust_360_View_Upload_16112021]
--ALTER PROC [dbo].[Cust_360_View_Upload]
--DECLARE
  @XmlDocument  XML
 ,@TimeKey INT
AS

BEGIN

--DECLARE
--  @XmlDocument XML = '<DataSet><GridData><ENTCIF>1152313</ENTCIF><CustomerID>10643458</CustomerID><PAN>AICPG5662J</PAN><AccountNumber>200003683341</AccountNumber></GridData><GridData><ENTCIF>1109714</ENTCIF><CustomerID>10643459</CustomerID><PAN>AJKPB2932K</PAN><AccountNumber>200003683358</AccountNumber></GridData><GridData><ENTCIF>1165981</ENTCIF><CustomerID>10643492</CustomerID><PAN>ABNPR8476K</PAN><AccountNumber>200003683365</AccountNumber></GridData><GridData><ENTCIF>808845</ENTCIF><CustomerID>10643493</CustomerID><PAN>ADOPR6474Q</PAN><AccountNumber>200003683372</AccountNumber></GridData><GridData><ENTCIF>736930</ENTCIF><CustomerID>10643494</CustomerID><PAN>AALPJ7330H</PAN><AccountNumber>200003683381</AccountNumber></GridData><GridData><ENTCIF>613091</ENTCIF><CustomerID>10643530</CustomerID><PAN>AABPT5954D</PAN><AccountNumber>200003593725</AccountNumber></GridData><GridData><ENTCIF>952842</ENTCIF><CustomerID>10643531</CustomerID><PAN>AFWPD9797A</PAN><AccountNumber>200003593732</AccountNumber></GridData><GridData><ENTCIF>1035240</ENTCIF><CustomerID>10643532</CustomerID><PAN>ALQPS2781M</PAN><AccountNumber>200003593741</AccountNumber></GridData><GridData><ENTCIF>1144612</ENTCIF><CustomerID>10643568</CustomerID><PAN>AACPM6108P</PAN><AccountNumber>200003593756</AccountNumber></GridData><GridData><ENTCIF>925747</ENTCIF><CustomerID>10643569</CustomerID><PAN>AABPK4443Q</PAN><AccountNumber>200003593763</AccountNumber></GridData></DataSet>'
--  ,@TimeKey INT = 26084

	IF OBJECT_ID('TEMPDB..#NCIF_NPAUpload')IS NOT NULL
	DROP TABLE #NCIF_NPAUpload 
	SELECT
	c.value('./ENTCIF[1]','VARCHAR(20)')ENTCIF
   ,c.value('./CustomerID[1]','varchar(20)')CustomerID
   ,c.value('./PAN[1]','varchar(20)')PAN
   ,c.value('./AccountNumber[1]','varchar(20)')CustomerACID
	INTO #NCIF_NPAUpload
	FROM @XmlDocument.nodes('DataSet/GridData') AS t(c)

	DROP TABLE IF EXISTS #FinalData
	CREATE TABLE #FinalData(NCIF_ID VARCHAR(20))

	;WITH CTE AS
	(
		SELECT  A.NCIF_Id AS NCIF_Id  FROM NPA_IntegrationDetails A
		INNER JOIN #NCIF_NPAUpload B 
			ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
				AND A.CustomerId=B.CustomerID
		WHERE ISNULL(A.CustomerId,'')<>'' AND ISNULL(B.CustomerID,'')<>''
		GROUP BY A.NCIF_Id 
		UNION ALL
		SELECT ENTCIF AS NCIF_Id FROM #NCIF_NPAUpload
		WHERE ISNULL(ENTCIF,'')<>''
		GROUP BY ENTCIF
		UNION ALL
		SELECT  A.NCIF_Id AS NCIF_Id  FROM NPA_IntegrationDetails A
		INNER JOIN #NCIF_NPAUpload B 
			ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
				AND A.PAN=B.PAN
		WHERE ISNULL(A.PAN,'')<>'' AND ISNULL(B.PAN,'')<>''
		GROUP BY A.NCIF_Id 

		UNION ALL
		SELECT  A.NCIF_Id AS NCIF_Id  FROM NPA_IntegrationDetails A
		INNER JOIN #NCIF_NPAUpload B 
			ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
				AND A.CustomerACID=B.CustomerACID
		WHERE ISNULL(A.CustomerACID,'')<>'' AND ISNULL(B.CustomerACID,'')<>''
		GROUP BY A.NCIF_Id 

	)

	INSERT INTO #FinalData
	SELECT NCIF_Id FROM CTE GROUP BY NCIF_Id

	/*create index for increase performance*/
	IF((SELECT COUNT(1) FROM #FinalData )>100)
		BEGIN
			 CREATE NONCLUSTERED INDEX IX_NCIF
			 ON  #FinalData(NCIF_Id)			
		END
	
	--select 111,* from #FinalData


	SELECT  
	A.NCIF_Id AS UCIF,
	A.CustomerId,
	ISNULL(A.PAN,'') as PAN,
	A.CustomerName,
	ISNULL(Cast(A.SrcSysAlt_Key as varchar(100)),'') SrcSysAlt_Key,
	ISNULL(D.SourceName,'') AS [Source System],
	A.CustomerACID AS [Account ID],
	ISNULL(Cast(A.Segment as varchar(100)),'') AS Segment,							-- Replaced By Satwaji(SubSegment to Segment) as on 19/08/2021 AS Per Bank's Requirement
	--ISNULL(Cast(A.SubSegment as varchar(100)),'') AS SubSegment,					-- Commented By Satwaji as on 19/08/2021 AS Per Bank's Requirement
	ISNULL(Cast(A.ProductCode as varchar(100)),'') AS SchemeProductCode,
	ISNULL(Cast(A.ProductDesc as varchar(100)),'') AS SchemeProductCodeDescription,
	Cast(ISNULL(A.SanctionedLimit,0) as varchar(200)) AS LimitSanctioned,
	Cast(ISNULL(A.Balance,0) as varchar(200)) as Balance,
	Cast(ISNULL(A.PrincipleOutstanding,0) as varchar(200)) as PrincipleOutstanding,
	ISNULL(Cast(A.AC_AssetClassAlt_Key as varchar(200)),'') as [AssetClass Alt_Key],
	ISNULL(B.AssetClassShortName,'') AS [Asset Classification],
	ISNULL(CONVERT(VARCHAR(10),A.AC_NPA_Date,103),'') AS [NPA Date],
	ISNULL(Cast(A.NCIF_AssetClassAlt_Key as varchar(100)),'') as NCIF_AssetClassAlt_Key,
	ISNULL(C.AssetClassShortName,'') AS UCIFAssetClassification,
	ISNULL(CONVERT(VARCHAR(10),A.NCIF_NPA_Date,103),'') AS UCIF_NPA_Date,
	--ISNULL(PNPA_Status,'N')AS [Potential NPA],									-- Commented By Satwaji as on 19/08/2021 AS Per Bank's Requirement
	--ISNULL(CONVERT(VARCHAR(10),PNPA_Date,103),'') AS [Potential NPA Date],		-- Commented By Satwaji as on 19/08/2021 AS Per Bank's Requirement
	--CASE WHEN ISNULL(AC_AssetClassAlt_Key,0)<>ISNULL(NCIF_AssetClassAlt_Key,0) THEN (CASE WHEN ISNULL(AC_AssetClassAlt_Key,0)<>1 AND ISNULL(NCIF_AssetClassAlt_Key,'')=1 THEN 'N' ELSE 'Y' END)  
	--ELSE 'N' END [Is Percolated],													-- Commented By Satwaji as on 19/08/2021 AS Per Bank's Requirement
	ISNULL(Cast(A.MaxDPD as varchar(100)),'') AS [DPD (MAX DPD)],
	Cast(ISNULL(A.PrincOverdue,0) as varchar(200)) as PrincipleOverdue,
	Cast(ISNULL(A.OtherOverdue,0) as varchar(200)) as OtherOverdue,

	--------------------- BELOW NEW COLUMNS ARE ADDED BY SATWAJI AS PER BANK'S REQUIREMENT AS ON 28/09/2021 ---------------------------
	ISNULL(Cast(A.DPD_Interest_Not_Serviced as varchar(100)),'') AS DPD_Interest_Not_Serviced,
	ISNULL(Cast(A.DPD_OtherOverdueSince as varchar(100)),'') AS DPD_OtherOverdueSince,			
	ISNULL(Cast(A.DPD_Overdrawn as varchar(100)),'') AS DPD_Overdrawn,							
	ISNULL(Cast(A.DPD_Overdue_Loans as varchar(100)),'') AS DPD_Overdue_Loans,					
	ISNULL(Cast(A.DPD_PrincOverdue as varchar(100)),'') AS DPD_PrincOverdue,					
	ISNULL(Cast(A.DPD_Renewals as varchar(100)),'') AS DPD_Renewals,							
	ISNULL(Cast(A.DPD_StockStmt as varchar(100)),'') AS DPD_StockStmt, 							
	ISNULL(CONVERT(VARCHAR(10),A.StkStmtDate,103),'') AS StkStmtDate,
	'' AS [DCCO Date],
	A.IsARC_Sale AS ARC,
	A.IsSuitFiled AS SUIT,
	A.IsOTS AS OTS,
	A.IsFraud AS FRAUD,
	A.WriteOffFlag,
	A.IsRestructured AS [Restructured Flag],
	ISNULL(Cast(ACRD.RestructureTypeAlt_Key as varchar(200)),'') AS [Restructured Type],	
	ISNULL(CONVERT(VARCHAR(10),ACRD.RestructureDt,103),'') AS [Restructured Date],	
	ISNULL(CONVERT(VARCHAR(10),ACRD.RepaymentStartDate,103),'') AS [First Repayment Date],
	A.FlgErosion AS [Security Erosion Flag],
	A.GtyRepudiated AS [Gty Repudiated],
	A.IsTWO AS IsTWO,	-- Added By Satwaji as on 08/10/2021 AS PER BANK's REQUIREMENT

	'360_Upload' AS [TableName] 
	FROM NPA_IntegrationDetails A
	
	INNER JOIN #FinalData		E  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
										AND A.NCIF_Id=E.NCIF_ID
	
	LEFT JOIN DimAssetClass     B  ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
									   AND A.AC_AssetClassAlt_Key=B.AssetClassAlt_Key
	
	LEFT JOIN DimAssetClass     C  ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
									   AND A.NCIF_AssetClassAlt_Key=C.AssetClassAlt_Key
	
	LEFT JOIN DimSourceSystem   D  ON (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
									   AND A.SrcSysAlt_Key=D.SourceAlt_Key

	LEFT JOIN AdvAcRestructureDetail  ACRD  ON (ACRD.EffectiveFromTimeKey<=@TimeKey AND ACRD.EffectiveToTimeKey>=@TimeKey)
												    AND ACRD.RefSystemAcId=A.CustomerACID
									   
	--WHERE EXISTS (SELECT NCIF_Id FROM #FinalData E
	--			  WHERE A.NCIF_Id=E.NCIF_ID
	--			 )																	
									    
	ORDER BY A.NCIF_Id,A.CustomerId,A.CustomerACID

	/*Excel upload validation*/

	--;WITH CTE_Val AS
	--(
	--	SELECT A.ENTCIF,A.CustomerID,CASE WHEN B.NCIF_Id IS NULL THEN 'Invalid NCIF_Id' END AS [ErrorMsg]
	--	FROM #NCIF_NPAUpload A
	--	LEFT JOIN NPA_IntegrationDetails B
	--		ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
	--			AND A.ENTCIF=B.NCIF_Id
	--	WHERE ISNULL(A.ENTCIF,'')<>'' AND ISNULL(A.CustomerID,'')=''			
	--	UNION ALL
	--	SELECT A.ENTCIF,A.CustomerID,CASE WHEN C.CustomerID	IS NULL THEN  'Invalid CustomerId' END AS [ErrorMsg]
	--	FROM #NCIF_NPAUpload A
	--	LEFT JOIN NPA_IntegrationDetails C 
	--		ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
	--			AND A.CustomerID=C.CustomerID
	--	WHERE ISNULL(A.CustomerID,'')<>''AND ISNULL(A.ENTCIF,'')=''
	--)
	--SELECT *,'Error' AS [TableName] FROM CTE_Val
	--WHERE [ErrorMsg] IS NOT NULL 
	--UNION ALL
	--SELECT *,'Required one input value'AS [ErrorMsg],'Error' AS [TableName]  FROM #NCIF_NPAUpload
	--WHERE ISNULL(ENTCIF,'')<>'' AND ISNULL(CustomerID,'')<>''


	DROP TABLE IF EXISTS #NCIF_NPAUpload
	DROP TABLE IF EXISTS #FinalData

END

GO