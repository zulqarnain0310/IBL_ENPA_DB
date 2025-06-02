SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[COBORROWERREPORTGENERATION_TEST_20250211](
		@TIMEKEY INT
)
AS
BEGIN
--select EffectiveFromTimeKey from  NPA_IntegrationDetails

DECLARE @Processingdate DATE=(SELECT DATE  FROM SysDataMatrix  WHERE TimeKey=@TIMEKEY)

DECLARE @DATE DATE = (SELECT DATE FROM SYSDATAMATRIX WHERE TIMEKEY = @TIMEKEY) 

DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='COBORROWERREPORTGENERATION' AND [EXT_DATE]=@Processingdate AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]
           ([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @Processingdate,@TimeKey,'COBORROWERREPORTGENERATION',GETDATE()


DROP TABLE IF EXISTS #NPA_IntegrationDetails
SELECT CustomerACID,SrcSysAlt_Key INTO #NPA_IntegrationDetails FROM NPA_IntegrationDetails WHERE CustomerACID IN (
SELECT ImpactingAccountNo FROM NPA_IntegrationDetails A WHERE A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY
)
 
--select * from #NPA_IntegrationDetails

--UPDATE A SET A.ImpactingSourceSystemName=C.SourceName,
--			A.ImpactingAccountNo=B.CustomerACID
--	FROM NPA_IntegrationDetails A INNER JOIN #NPA_IntegrationDetails B ON A.ImpactingAccountNo=B.CustomerACID
--	INNER JOIN DimSourceSystem C ON B.SrcSysAlt_Key=C.SourceAlt_Key
--	WHERE A.NatureofClassification<>'C'
--	AND A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY
--	AND A.ImpactingSourceSystemName IS NULL


DROP TABLE IF EXISTS #CoBorrowerData_Curnt 
SELECT DISTINCT A.CUSTOMERNAME COBO_CUSTOMERNAME,
A.CustomerACID CustomerACID_COBORROWER,B.* 
INTO #CoBorrowerData_curnt 
FROM CoBorrowerData_curnt B 
LEFT JOIN NPA_IntegrationDetails A 
ON B.NCIFID_COBORROWER=A.NCIF_Id
WHERE B.NCIFID_COBORROWER IS NOT NULL ----ADDED ON 20231223 OBSERVATION ON COUNT MISMATCH IN NPA LISTING AND COBO REPORT


--SELECT * FROM #CoBorrowerData_curnt WHERE CustomerName IS NOT NULL
DROP TABLE IF EXISTS #NCIF_ID
SELECT DISTINCT NCIF_ID,
D.COBO_CUSTOMERNAME,D.NCIFID_COBORROWER,
D.NCIFID_PRIMARYACCOUNT,D.CustomerACID_PrimaryAccount,
A.CustomerACID,A.CUSTOMERID,A.NATUREOFCLASSIFICATION 
INTO #NCIF_ID 
FROM NPA_IntegrationDetails A	INNER JOIN
#CoBorrowerData_curnt D ON D.NCIFID_COBORROWER=A.NCIF_ID
AND D.CustomerACID_PrimaryAccount=A.CUSTOMERACID--ADDED ON 20231101
								--where NATUREOFCLASSIFICATION IS NOT NULL

UNION 
SELECT DISTINCT NCIF_ID,D.COBO_CUSTOMERNAME,D.NCIFID_COBORROWER,D.NCIFID_PRIMARYACCOUNT
,D.CustomerACID_PrimaryAccount,A.CustomerACID,A.CUSTOMERID,A.NATUREOFCLASSIFICATION  
FROM NPA_IntegrationDetails A	INNER JOIN
#CoBorrowerData_curnt D ON D.NCIFID_PRIMARYACCOUNT=A.NCIF_ID
						AND D.CustomerACID_PrimaryAccount=A.CUSTOMERACID--ADDED ON 20231101
								--where NATUREOFCLASSIFICATION IS NOT NULL
								
								

--SELECT * FROM #NCIF_ID WHERE NCIF_ID IN ('11169450','45856545')

DROP TABLE IF EXISTS #REPORT 
SELECT DISTINCT
B.SourceName
,A.BranchCode SolId
,A.Segment
,A.ProductCode
,A.NCIF_Id
,A.CustomerId
,A.CustomerACID
,A.IsFunded
,A.CustomerName
,A.NCIF_NPA_Date
,C.AssetClassName
,A.Balance
,A.IntOverdue
,A.PrincipleOutstanding
,A.SecurityValue
,A.SecuredAmt
,A.UnSecuredAmt
,A.TotalProvision
,A.SecuredFlag
,D.NCIFID_COBORROWER Co_Borrower_NCIF
,(CASE WHEN D.NCIFID_COBORROWER IS NULL THEN NULL ELSE D.COBO_CUSTOMERNAME END) Co_Borrower_Name
,A.NATUREOFCLASSIFICATION Culprit_Impacted--CHANGE ALIAS A FROM D 20231104
,CASE WHEN A.NATUREOFCLASSIFICATION IN ('C') AND NCIFID_COBORROWER IS NOT NULL THEN 'Y' ELSE 'N' END Co_borrower_impacted--ADDED  NCIFID_COBORROWER IS NOT NULL  ON 20231110 BY ZAIN
,CASE WHEN A.ImpactingAccountNo IS NULL THEN 'N'-- CHANGE  20231219
 WHEN A.ImpactingAccountNo IS not NULL  and A.DateofImpacting<>@DATE THEN 'N' --CHANGE  20231219
 ELSE
'Y' END PBos_Culprit_Impact
,--CASE WHEN D.NATUREOFCLASSIFICATION =  'C' THEN 
CASE WHEN A.NATUREOFCLASSIFICATION IN ('V','D')  THEN A.ImpactingAccountNo ELSE NULL END  --ELSE NULL END 
PBos_Culprit_ACID
,CASE WHEN A.NATUREOFCLASSIFICATION IN ('C')  THEN NULL ELSE A.ImpactingSourceSystemName END ImpactingSourceSystemName
--,A.ImpactingAccountNo Impacting_ACID
,(CASE WHEN ISNULL(A.NCIF_AssetClassAlt_Key,1) IN (1,7)  THEN NULL 
		WHEN A.NatureofClassification IN ('C','V','D') AND ISNULL(A.NCIF_AssetClassAlt_Key,1)NOT IN (1,7) THEN ISNULL(A.NCIF_NPA_Date,A.DateofImpacting) ELSE NULL END )Date_of_identification_of_culprit_ac--reversed (A.DateofImpacting,A.NCIF_NPA_Date) as per observation raised by FRR on 20231225
,E.RestructureDt
,A.WriteOffFlag
,A.WriteOffDate 
INTO #REPORT 
FROM NPA_IntegrationDetails A	
LEFT JOIN #NCIF_ID D ON D.NCIF_ID=A.NCIF_ID--CHANGE INNER JOIN TO LEFT JOIN 20231104
AND A.CustomerACID=D.CustomerACID
INNER JOIN DIMSOURCESYSTEM B ON  A.SRCSYSALT_KEY=B.SOURCEALT_KEY
LEFT JOIN  DIMASSETCLASS C ON C.AssetClassAlt_Key=ISNULL(A.NCIF_ASSETCLASSALT_KEY,1)
LEFT JOIN CURDAT.AdvAcRestructureDetail E ON A.CustomerACID=E.RefSystemAcId AND A.NCIF_Id=E.RefCustomer_CIF 
		where A.EFFECTIVEFROMTIMEKEY<=@TIMEKEY
			AND A.EFFECTIVETOTIMEKEY>=@TIMEKEY
--			AND A.NCIF_ASSETCLASSALT_KEY NOT IN (1,7)
			AND A.NATUREOFCLASSIFICATION IS NOT NULL--CHANGE ADDED 20231104




DROP TABLE If EXISTS COBORROWERREPORT
SELECT * INTO COBORROWERREPORT FROM #REPORT

--SELECT count(1) FROM COBORROWERREPORT



DROP TABLE IF EXISTS #TEMP1
SELECT  A.SourceSystemName_PrimaryAccount,A.NCIFID_PRIMARYACCOUNT,A.NCIFID_COBORROWER, A.CustomerACId_PrimaryAccount
INTO #TEMP1 
FROM #CoBorrowerData_curnt  A WHERE A.NCIFID_COBORROWER NOT IN (SELECT  B.NCIF_ID FROM NPA_IntegrationDetails B  ) 
AND  A.ACDEGFLG='Y' --AND ASONDATE=@DATE
GROUP BY A.NCIFID_PRIMARYACCOUNT,A.NCIFID_COBORROWER, A.CustomerACId_PrimaryAccount,A.SourceSystemName_PrimaryAccount


DROP TABLE IF EXISTS #TEMP2
SELECT A.*,MAX(B.NCIF_ASSETCLASSALT_KEY) NCIF_ASSETCLASSALT_KEY,MIN(B.NCIF_NPA_DATE)NCIF_NPA_DATE
INTO #TEMP2 
FROM #TEMP1 A INNER JOIN NPA_IntegrationDetails B ON A.CustomerACId_PrimaryAccount=B.CUSTOMERACID
																	AND ISNULL(NCIF_ASSETCLASSALT_KEY,1) IN (2,3,4,5,6,7)																	
WHERE B.EFFECTIVEFROMTIMEKEY<=@TIMEKEY AND B.EFFECTIVETOTIMEKEY<=@TIMEKEY 
		AND NATUREOFCLASSIFICATION = 'C'
GROUP BY A.NCIFID_PRIMARYACCOUNT,A.NCIFID_COBORROWER, A.CustomerACId_PrimaryAccount,A.SourceSystemName_PrimaryAccount


/*FOR INACTIVE COBORROWER ADDED ON 20250211 BY MOHIT FOR WO COBORROWER's*/
INSERT INTO #TEMP2(NCIFID_PRIMARYACCOUNT,NCIF_ASSETCLASSALT_KEY)
SELECT DISTINCT A.NCIFID_COBORROWER,2
FROM #CoBorrowerData_curnt A WHERE A.NCIFID_COBORROWER NOT IN (SELECT  B.NCIF_ID FROM NPA_IntegrationDetails B  ) 
AND  A.ACDEGFLG='Y' --AND ASONDATE=@DATE
GROUP BY A.NCIFID_PRIMARYACCOUNT,A.NCIFID_COBORROWER, A.CustomerACId_PrimaryAccount,A.SourceSystemName_PrimaryAccount
/*FOR INACTIVE COBORROWER ADDED ON 20250211 BY MOHIT FOR WO COBORROWER's END*/

INSERT INTO #REPORT(NCIF_ID,Co_Borrower_NCIF,SOURCENAME,NCIF_NPA_Date,ASSETCLASSNAME,Culprit_Impacted,Co_borrower_impacted,PBos_Culprit_Impact,PBos_Culprit_ACID)
SELECT DISTINCT A.NCIFID_PRIMARYACCOUNT,A.NCIFID_COBORROWER,CASE WHEN A.SourceSystemName_PrimaryAccount LIKE '%PT%' then 'PT Smart' else A.SourceSystemName_PrimaryAccount end,A.NCIF_NPA_Date,C.ASSETCLASSNAME,'C','Y','Y',A.CustomerACId_PrimaryAccount
FROM #TEMP2 A
INNER JOIN  DIMASSETCLASS C ON C.AssetClassAlt_Key=ISNULL(A.NCIF_ASSETCLASSALT_KEY,1)
--WHERE A.NCIF_ASSETCLASSALT_KEY<>7 /*FOR INACTIVE COBORROWER ADDED ON 20250211 BY MOHIT FOR WO COBORROWER's END*/

DROP TABLE IF EXISTS COBORROWERREPORTDEGRADEINACTIVE
SELECT DISTINCT * INTO COBORROWERREPORTDEGRADEINACTIVE FROM #REPORT WHERE CUSTOMERACID IS NULL ORDER BY 1,5,20



DROP TABLE IF EXISTS COBO_REPORT_1
DROP TABLE IF EXISTS COBO_REPORT_2

SELECT A.SourceName
,A.SolId
,A.Segment
,A.ProductCode
,A.NCIF_Id
,A.CustomerId
,A.CUSTOMERACID
,A.IsFunded
,A.CustomerName
,A.NCIF_NPA_Date
,A.AssetClassName
,A.Balance
,A.IntOverdue
,A.PrincipleOutstanding
,A.SecurityValue
,A.SecuredAmt
,A.UnSecuredAmt
,A.TotalProvision
,A.SecuredFlag
,STRING_AGG(Co_Borrower_Name,',') Co_Borrower_Name
,STRING_AGG(Co_Borrower_NCIF,',') Co_Borrower_NCIF
,Culprit_Impacted  
,Co_borrower_impacted
,case when Culprit_Impacted='C' then 'N' else  PBos_Culprit_Impact end PBos_Culprit_Impact
,STRING_AGG(PBos_Culprit_ACID,',') PBos_Culprit_ACID
,STRING_AGG(ImpactingSourceSystemName,',') ImpactingSourceSystemName
,Date_of_identification_of_culprit_ac
,RestructureDt
--,A.WriteOffFlag
--,A.WriteOffDate
INTO COBO_REPORT_1
 FROM COBORROWERREPORT A
GROUP BY 
A.SourceName
,A.SolId
,A.Segment
,A.ProductCode
,A.NCIF_Id
,A.CustomerId
,A.CustomerACID
,A.IsFunded
,A.CustomerName
,A.NCIF_NPA_Date
,A.AssetClassName
,A.Balance
,A.IntOverdue
,A.PrincipleOutstanding
,A.SecurityValue
,A.SecuredAmt
,A.UnSecuredAmt
,A.TotalProvision
,A.SecuredFlag
--,Co_Borrower_Name
,Culprit_Impacted
,Co_borrower_impacted
,PBos_Culprit_Impact
,Date_of_identification_of_culprit_ac
,RestructureDt
--,A.WriteOffFlag
--,A.WriteOffDate
ORDER BY NCIF_ID
--[dbo].[COBORROWERREPORTGENERATION] @TIMEKEY


SELECT A.SourceName
,A.SolId
,A.Segment
,A.ProductCode
,A.NCIF_Id
,A.CustomerId
,A.CUSTOMERACID
,A.IsFunded
,A.CustomerName
,A.NCIF_NPA_Date
,A.AssetClassName
,A.Balance
,A.IntOverdue
,A.PrincipleOutstanding
,A.SecurityValue
,A.SecuredAmt
,A.UnSecuredAmt
,A.TotalProvision
,A.SecuredFlag
,STRING_AGG(Co_Borrower_Name,',') Co_Borrower_Name
,STRING_AGG(Co_Borrower_NCIF,',') Co_Borrower_NCIF
,Culprit_Impacted  
,Co_borrower_impacted
,PBos_Culprit_Impact
,STRING_AGG(PBos_Culprit_ACID,',') PBos_Culprit_ACID
,STRING_AGG(ImpactingSourceSystemName,',') ImpactingSourceSystemName
,Date_of_identification_of_culprit_ac
,RestructureDt
--,A.WriteOffFlag
--,A.WriteOffDate
INTO COBO_REPORT_2
 FROM COBORROWERREPORTDEGRADEINACTIVE A
GROUP BY 
A.SourceName
,A.SolId
,A.Segment
,A.ProductCode
,A.NCIF_Id
,A.CustomerId
,A.CustomerACID
,A.IsFunded
,A.CustomerName
,A.NCIF_NPA_Date
,A.AssetClassName
,A.Balance
,A.IntOverdue
,A.PrincipleOutstanding
,A.SecurityValue
,A.SecuredAmt
,A.UnSecuredAmt
,A.TotalProvision
,A.SecuredFlag
--,Co_Borrower_Name
,Culprit_Impacted
,Co_borrower_impacted
,PBos_Culprit_Impact
,Date_of_identification_of_culprit_ac
,RestructureDt
--,A.WriteOffFlag
--,A.WriteOffDate

ORDER BY NCIF_ID



DROP TABLE IF EXISTS COBO_REPORT1
DROP TABLE IF EXISTS COBO_REPORT2

select * into COBO_REPORT1 from COBO_REPORT_1 where AssetClassName<>'STANDARD' AND ISNULL(Balance,0)>=0/*FOR INACTIVE COBORROWER ADDED ON 20250211 BY MOHIT FOR ZERO BALANCE END*/
select * into COBO_REPORT2 from COBO_REPORT_2 where AssetClassName<>'STANDARD' AND ISNULL(Balance,0)>=0/*FOR INACTIVE COBORROWER ADDED ON 20250211 BY MOHIT FOR ZERO BALANCE END*/


/*HANDELING REPEATED NCIF_ID IN Co_Borrower_NCIF COLUMN*/

DROP TABLE IF EXISTS #DUPLICATECOBO_NCIF_HANDLE
SELECT DISTINCT NCIF_Id,CUSTOMERACID,Co_Borrower_NCIF,VALUE INTO #DUPLICATECOBO_NCIF_HANDLE
FROM COBO_REPORT1
    CROSS APPLY STRING_SPLIT(Co_Borrower_NCIF, ',')
	WHERE Co_Borrower_NCIF LIKE '%,%'
	;
	--SELECT * FROM #DUPLICATECOBO_NCIF_HANDLE 
	
	DROP TABLE IF EXISTS #DUPLICATECOBO_NCIF_HANDLE_FIN
	SELECT CUSTOMERACID,STRING_AGG(value,',')Co_Borrower_NCIF INTO #DUPLICATECOBO_NCIF_HANDLE_FIN FROM #DUPLICATECOBO_NCIF_HANDLE
	GROUP BY CUSTOMERACID

	--SELECT * FROM #DUPLICATECOBO_NCIF_HANDLE_FIN 

	UPDATE A SET  A.Co_Borrower_NCIF=B.Co_Borrower_NCIF
	FROM COBO_REPORT1 A INNER JOIN #DUPLICATECOBO_NCIF_HANDLE_FIN B ON A.CUSTOMERACID=B.CUSTOMERACID
----------------------------------------HANDELING ENDED--------------------------------


/*HANDELING REPEATED NCIF_ID IN Co_Borrower_NCIF COLUMN*/
DROP TABLE IF EXISTS #DUPLICATE_PBO_ACID_HANDLE
SELECT DISTINCT NCIF_Id,CUSTOMERACID,PBos_Culprit_ACID,VALUE INTO #DUPLICATE_PBO_ACID_HANDLE
FROM COBO_REPORT1
		CROSS APPLY STRING_SPLIT(PBos_Culprit_ACID, ',')
	WHERE PBos_Culprit_ACID LIKE '%,%'
	;
	--SELECT * FROM #DUPLICATE_PBO_ACID_HANDLE 
	
	DROP TABLE IF EXISTS #DUPLICATE_PBO_ACID_HANDLE_FIN
	SELECT CUSTOMERACID,STRING_AGG(value,',')PBos_Culprit_ACID INTO #DUPLICATE_PBO_ACID_HANDLE_FIN FROM #DUPLICATE_PBO_ACID_HANDLE
	GROUP BY CUSTOMERACID

	--SELECT * FROM #DUPLICATE_PBO_ACID_HANDLE_FIN 

	
	UPDATE A SET  A.PBos_Culprit_ACID=B.PBos_Culprit_ACID
	FROM COBO_REPORT1 A INNER JOIN #DUPLICATE_PBO_ACID_HANDLE_FIN B ON A.CUSTOMERACID=B.CUSTOMERACID

----------------------------------------HANDELING ENDED--------------------------------

	/*TO UPDATE CO_BORROWER_NCIF IN REPORT BASIS OF PBO ACID ADDED ON 20231207*/
	---NOT REQUIRED
			--UPDATE A SET A.Co_Borrower_NCIF=B.NCIFID_PrimaryAccount
			--			,A.Co_Borrower_Name=C.CustomerName
			--from COBO_REPORT1 A 
			--INNER JOIN CoBorrowerData_curnt B ON A.PBos_Culprit_ACID=B.CustomerACID_PrimaryAccount
			--INNER JOINNPA_IntegrationDetails C ON C.CustomerACID=A.PBos_Culprit_ACID
			--where A.Co_Borrower_NCIF IS NULL AND A.PBos_Culprit_ACID IS NOT NULL AND A.Culprit_Impacted='D'

	/*SELF DEGRADED ACCOUNTS  THROUGH PERCOLATION AND NO COBORROWER RELATION ADDED ON 20231207*/

			UPDATE A SET 
			A.PBos_Culprit_Impact='N',A.PBos_Culprit_ACID=NULL,A.ImpactingSourceSystemName=NULL
			 from COBO_REPORT1 A 
			INNER JOIN CoBorrowerData_curnt B ON A.PBos_Culprit_ACID=B.CustomerACID_PrimaryAccount
			where A.Co_Borrower_NCIF IS NULL AND A.PBos_Culprit_ACID IS NOT NULL AND A.Culprit_Impacted='V'

			UPDATE A SET 
			A.PBos_Culprit_Impact='N',A.PBos_Culprit_ACID=NULL,A.ImpactingSourceSystemName=NULL
			 from COBO_REPORT1 A 
			INNER JOIN CoBorrowerData_curnt B ON A.PBos_Culprit_ACID<>B.CustomerACID_PrimaryAccount
			where A.Co_Borrower_NCIF IS NULL AND A.PBos_Culprit_ACID IS NOT NULL AND A.Culprit_Impacted='V'


/*UPDATE ALL PERCOLATED ACCOUNTS AS NULL FOR BELOW FIELDS ADDED ON 20231207*/
			UPDATE A SET 
			A.PBos_Culprit_Impact='N',A.PBos_Culprit_ACID=NULL,A.ImpactingSourceSystemName=NULL
			 from COBO_REPORT1 A 
			where A.Culprit_Impacted='V'	


			/*ADDED ASPER OBSERVATION OF 20231221 THAT D ACCOUNTS COMING FROM SOURCE HAVING ACCOUNT NUMBER OF V ACCOUNTS AS PER OUR PROCESS*/
			UPDATE B SET B.PBos_Culprit_ACID =NULL 
						,B.ImpactingSourceSystemName =NULL 
						,B.Date_of_identification_of_culprit_ac=A.NCIF_NPA_Date
			FROM NPA_IntegrationDetails A INNER JOIN
			COBO_REPORT1 B ON A.CustomerACID =B.PBos_Culprit_ACID 
			AND A.NatureofClassification='V'

			/*ADDED ASPER OBSERVATION OF 20231221 THAT ACCOUNTS COMING FROM SOURCE AS C HAVING COBO AS 'C' SHOULD HAVE PBos_Culprit_ACID AS 'N'*/
			UPDATE B SET B.Co_borrower_impacted='N'
			FROM NPA_IntegrationDetails A INNER JOIN
			COBO_REPORT1 B ON A.NCIF_Id =B.Co_Borrower_NCIF 
			AND A.NatureofClassification='C'
			AND B.Culprit_Impacted='C'
			AND B.Co_Borrower_NCIF IS NOT NULL
			
			
DROP TABLE IF EXISTS COBO_FINAL
SELECT 
	 SourceName,SolId,Segment,ProductCode,NCIF_Id,CustomerId,CUSTOMERACID,IsFunded,CustomerName,NCIF_NPA_Date,AssetClassName,Balance
	,IntOverdue,PrincipleOutstanding,SecurityValue,SecuredAmt,UnSecuredAmt,TotalProvision,SecuredFlag,Co_Borrower_Name,Co_Borrower_NCIF
	,Culprit_Impacted,Co_borrower_impacted,PBos_Culprit_Impact,PBos_Culprit_ACID,ImpactingSourceSystemName,Date_of_identification_of_culprit_ac,RestructureDt
	INTO COBO_FINAL 
	FROM COBO_REPORT1 
	--where AssetClassName Not in ('WRITE OFF') AND Balance>0/*FOR INACTIVE COBORROWER ADDED ON 20250211 BY MOHIT FOR ZERO BALANCE END*/
UNION ALL
SELECT 
	 SourceName,SolId,Segment,ProductCode,NCIF_Id,CustomerId,CUSTOMERACID,IsFunded,CustomerName,NCIF_NPA_Date,AssetClassName,Balance
	,IntOverdue,PrincipleOutstanding,SecurityValue,SecuredAmt,UnSecuredAmt,TotalProvision,SecuredFlag,Co_Borrower_Name,Co_Borrower_NCIF
	,Culprit_Impacted,Co_borrower_impacted,PBos_Culprit_Impact,PBos_Culprit_ACID,ImpactingSourceSystemName,Date_of_identification_of_culprit_ac,RestructureDt
	FROM COBO_REPORT2 
	--where AssetClassName Not in ('WRITE OFF') AND Balance>0/*FOR INACTIVE COBORROWER ADDED ON 20250211 BY MOHIT FOR ZERO BALANCE END*/

/**** New COBO report with write off and standalone COBO records change by Liyaqat on 2024  ****/

					Drop table if exists #DegNCIF_COBOdata
							select distinct NCIFID_COBORROWER into #DegNCIF_COBOdata from dbo.CoBorrowerData_curnt
							where AcDegFlg='Y'
							UNION
							select distinct NCIFID_PrimaryAccount from dbo.CoBorrowerData_curnt
							where AcDegFlg='Y' 
--select COUNT(1) from #DegNCIF_COBOdata---1508723 ---289091
					
	Drop table if exists WrtoffCOBOdata
			select SourceName,SolId,Segment,ProductCode,NCIF_Id,CustomerId,CUSTOMERACID,IsFunded,CustomerName,NCIF_NPA_Date,AssetClassName,Balance,IntOverdue,PrincipleOutstanding
					,SecurityValue,SecuredAmt,UnSecuredAmt,TotalProvision,SecuredFlag,Co_Borrower_Name,Co_Borrower_NCIF,Culprit_Impacted,Co_borrower_impacted,PBos_Culprit_Impact
					,PBos_Culprit_ACID,ImpactingSourceSystemName,Date_of_identification_of_culprit_ac,RestructureDt,WriteOffFlag,WriteOffDate
				 Into WrtoffCOBOdata from [dbo].COBORROWERREPORT a Join #DegNCIF_COBOdata B on a.NCIF_ID=B.NCIFID_COBORROWER
				where ISNULL(AssetClassName,'')='WRITE OFF' 

--select COUNT(1) from WrtoffCOBOdata ---1508723 ---289091

	Drop table if exists ZeroBalCOBOdata
			select SourceName,SolId,Segment,ProductCode,NCIF_Id,CustomerId,CUSTOMERACID,IsFunded,CustomerName,NCIF_NPA_Date,AssetClassName,Balance,IntOverdue,PrincipleOutstanding
					,SecurityValue,SecuredAmt,UnSecuredAmt,TotalProvision,SecuredFlag,Co_Borrower_Name,Co_Borrower_NCIF,Culprit_Impacted,Co_borrower_impacted,PBos_Culprit_Impact
					,PBos_Culprit_ACID,ImpactingSourceSystemName,Date_of_identification_of_culprit_ac,RestructureDt,WriteOffFlag,WriteOffDate
				 Into ZeroBalCOBOdata from [dbo].COBORROWERREPORT a Join #DegNCIF_COBOdata B on a.NCIF_ID=B.NCIFID_COBORROWER
				where  Balance<=0 and  ISNULL(AssetClassName,'') not in ('' ,'WRITE OFF')

	Drop table if exists  StandaloneCobodata
		select distinct a.NCIFID_COBORROWER into  StandaloneCobodata from CoBorrowerData_curnt a 
			Inner Join NPA_IntegrationDetails c on a.NCIFID_PrimaryAccount=c.NCIF_Id And ISNULL(C.NCIF_ASSETCLASSALT_KEY,1)<>1
			Left Join NPA_IntegrationDetails b on a.NCIFID_COBORROWER=b.NCIF_Id   
			where b.NCIF_Id is NULL
	--select * from #StandaloneCobodata

DROP TABLE IF EXISTS COBO_FINAL_WOZeroAcct ------ Report with Write off accounts,Zero balace accounts & Standalone Coborrower

	SELECT  SourceName,SolId,Segment,ProductCode,NCIF_Id,CustomerId,CUSTOMERACID,IsFunded,CustomerName,NCIF_NPA_Date,AssetClassName,Balance,IntOverdue,PrincipleOutstanding
					,SecurityValue,SecuredAmt,UnSecuredAmt,TotalProvision,SecuredFlag,Co_Borrower_Name,Co_Borrower_NCIF,Culprit_Impacted,Co_borrower_impacted,PBos_Culprit_Impact
					,PBos_Culprit_ACID,ImpactingSourceSystemName,Date_of_identification_of_culprit_ac,RestructureDt
					--,WriteOffFlag,WriteOffDate
				  INTO COBO_FINAL_WOZeroAcct FROM COBO_REPORT1 
	UNION  
	SELECT SourceName,SolId,Segment,ProductCode,NCIF_Id,CustomerId,CUSTOMERACID,IsFunded,CustomerName,NCIF_NPA_Date,AssetClassName,Balance,IntOverdue,PrincipleOutstanding
					,SecurityValue,SecuredAmt,UnSecuredAmt,TotalProvision,SecuredFlag,Co_Borrower_Name,Co_Borrower_NCIF,Culprit_Impacted,Co_borrower_impacted,PBos_Culprit_Impact
					,PBos_Culprit_ACID,ImpactingSourceSystemName,Date_of_identification_of_culprit_ac,RestructureDt
					--,WriteOffFlag,WriteOffDate
				  FROM COBO_REPORT2
	UNION  
	SELECT SourceName,SolId,Segment,ProductCode,NCIF_Id,CustomerId,CUSTOMERACID,IsFunded,CustomerName,NCIF_NPA_Date,AssetClassName,Balance,IntOverdue,PrincipleOutstanding
					,SecurityValue,SecuredAmt,UnSecuredAmt,TotalProvision,SecuredFlag,Co_Borrower_Name,Co_Borrower_NCIF,Culprit_Impacted,Co_borrower_impacted,PBos_Culprit_Impact
					,PBos_Culprit_ACID,ImpactingSourceSystemName,Date_of_identification_of_culprit_ac,RestructureDt,WriteOffFlag,WriteOffDate
				  FROM WrtoffCOBOdata 
	UNION  
	SELECT SourceName,SolId,Segment,ProductCode,NCIF_Id,CustomerId,CUSTOMERACID,IsFunded,CustomerName,NCIF_NPA_Date,AssetClassName,Balance,IntOverdue,PrincipleOutstanding
					,SecurityValue,SecuredAmt,UnSecuredAmt,TotalProvision,SecuredFlag,Co_Borrower_Name,Co_Borrower_NCIF,Culprit_Impacted,Co_borrower_impacted,PBos_Culprit_Impact
					,PBos_Culprit_ACID,ImpactingSourceSystemName,Date_of_identification_of_culprit_ac,RestructureDt
					--,WriteOffFlag,WriteOffDate
				  FROM ZeroBalCOBOdata 
	UNION  
	Select  
		NULL as SourceName 
		,NULL as SolId
		,NULL as Segment
		,NULL as ProductCode
		,NCIFID_COBORROWER as NCIF_Id
		,NULL as CustomerId
		,NULL as CUSTOMERACID
		,NULL as IsFunded
		,NULL as CustomerName
		,NULL as NCIF_NPA_Date
		,NULL as AssetClassName
		,NULL as Balance
		,NULL as IntOverdue
		,NULL as PrincipleOutstanding
		,NULL as SecurityValue
		,NULL as SecuredAmt
		,NULL as UnSecuredAmt
		,NULL as TotalProvision
		,NULL as SecuredFlag
		,NULL as Co_Borrower_Name
		,NULL as Co_Borrower_NCIF
		,NULL as Culprit_Impacted
		,NULL as Co_borrower_impacted
		,NULL as PBos_Culprit_Impact
		,NULL as PBos_Culprit_ACID
		,NULL as ImpactingSourceSystemName
		,NULL as Date_of_identification_of_culprit_ac
		,NULL as RestructureDt
		,NULL as WriteOffFlag
		,NULL as WriteOffDate from StandaloneCobodata

UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='COBORROWERREPORTGENERATION' AND [EXT_DATE]=@Processingdate AND ISNULL([Audit_Flg],0)=0
 
END
 
GO