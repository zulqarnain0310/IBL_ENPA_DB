SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
create PROC [dbo].[REVERSE_FFEED_CLUB_PROCESS] AS
DECLARE @EXT_DATE_2 DATE='2024-01-18'


--SELECT		A.* 
--FROM		ReverseFeedDetails_After_18thProcess A 
--INNER JOIN	ReverseFeedDetails_After_19thProcess B
--ON			A.AccountNo=B.ACCOUNTNO--139875
--AND			A.NatureofClassification IS NOT NULL--NPA IN 17TH
--AND			B.NatureofClassification IS NOT NULL--NPA IN 18TH


/*COMMON CASES AND NPA ON  17 AND 18 -- 139816  RETAIN 17*/


/*If account is npa in 17th Jan data and 18th Jan data both then 17 reverse feed will be take as final –  
Additional comment from bank - Earliest NPA date and worst NPA classification should be taken.  */


--MATCHED IN 17 AND 18
--SELECT COUNT(1) FROM RF_2 --DONE
--SELECT A.*  INTO RF_1
SELECT A.*  INTO RF_1
FROM ReverseFeedDetails_After_18thProcess A INNER JOIN ReverseFeedDetails_After_19thProcess B
ON A.AccountNo=B.ACCOUNTNO
AND A.HOMOGENIZEDASSETCLASS=B.HOMOGENIZEDASSETCLASS
AND A.NatureofClassification=B.NatureofClassification-- 138684


--HOMOGENIZED CLASS CHANGED TO WORST IN 17 < 18 RETAIN 18
--SELECT B.*  INTO RF_2 --DONE
SELECT A.*  INTO RF_2
FROM ReverseFeedDetails_After_18thProcess A INNER JOIN ReverseFeedDetails_After_19thProcess B
ON A.AccountNo=B.ACCOUNTNO
AND A.HOMOGENIZEDASSETCLASS<B.HOMOGENIZEDASSETCLASS
AND A.NatureofClassification=B.NatureofClassification--1131

--HOMOGENIZED CLASS CHANGED TO BEST IN 17 > 18 RETAIN 18

--SELECT B.*  INTO RF_3--DONE
SELECT A.*  INTO RF_3
FROM ReverseFeedDetails_After_18thProcess A INNER JOIN ReverseFeedDetails_After_19thProcess B
ON A.AccountNo=B.ACCOUNTNO
AND A.HOMOGENIZEDASSETCLASS>B.HOMOGENIZEDASSETCLASS
AND A.NatureofClassification=B.NatureofClassification--1

/*COMMON CASES BUT CHANGE IN NATURE OF CLASSIFICATION--59 RETAIN 18*/

--SELECT A.*  INTO RF_6--DONE
SELECT A.*  INTO RF_6
FROM ReverseFeedDetails_After_18thProcess A INNER JOIN ReverseFeedDetails_After_19thProcess B
ON A.AccountNo=B.ACCOUNTNO
AND A.NatureofClassification<>B.NatureofClassification--47
AND A.NatureofClassification IS  NOT NULL
AND B.NatureofClassification IS  NOT NULL
AND  B.NatureofClassification<>'C'

--SELECT B.*  INTO RF_7--DONE
SELECT A.*  INTO RF_7
FROM ReverseFeedDetails_After_18thProcess A INNER JOIN ReverseFeedDetails_After_19thProcess B
ON A.AccountNo=B.ACCOUNTNO
AND A.NatureofClassification<>B.NatureofClassification--12
AND A.NatureofClassification IS  NOT NULL
AND B.NatureofClassification IS  NOT NULL
AND  B.NatureofClassification='C'

--SELECT 138684+1131+1
/*COMMON CASES AND NPA ON 17 AND STANDARD 18-- 32  RETAIN 18*/

/*If account is npa in 17th jan data and std in 18th jan data, on 18 data we will check the dpd it should be zero and on 17th Jan data dcco should be null, then we will take 18th Jan RF as final output or else we will take 17th Jan RF as final output –  
Additional comment from bank - all exceptional flags to be checked except dcco */

SELECT CUSTOMERACID INTO #TEMP FROM NPA_IntegrationDetails_After_18thProcess 
WHERE DCCO_DATE<'2024-01-17' AND PROJ_COMPLETION_DATE IS NULL AND 
EFFECTIVEFROMTIMEKEY<=27045  AND EFFECTIVETOTIMEKEY>=27045

--IF DCCO DATE IS AVAILABLE AND DCCO DATE<EXT_DATE THEN RETAIN 17 ELSE 18*/
--SELECT A.*  INTO RF_4--DONE
SELECT A.* INTO #TEMP_1
FROM ReverseFeedDetails_After_18thProcess A INNER JOIN ReverseFeedDetails_After_19thProcess B
ON A.AccountNo=B.ACCOUNTNO--32
INNER JOIN #TEMP C ON C.CUSTOMERACID=A.ACCOUNTNO
AND A.NatureofClassification IS NOT NULL--NPA IN 17TH
AND B.NatureofClassification IS NULL--UPGRADED IN 18TH

select * INTO RF_4  from #TEMP_1

--DCCO DATE END

--DPD NOT REQUIRED AS UPGRADATION ONLY HAPPENDS IN D2K .SO IF AN ACCOUNT HAVING DPD 100 ON DAY 1 AND 70 ON DAY 2 IT WILL BE NPA ONLY UNLESS ON DAY 2 IT IS 0 DPD

SELECT A.CUSTOMERACID INTO #TEMP_DPD_0 
FROM NPA_IntegrationDetails_After_18thProcess A 
INNER JOIN NPA_IntegrationDetails_After_19thProcess B 
ON A.CUSTOMERACID=B.CUSTOMERACID--32
 AND A.NCIF_ASSETCLASSALT_KEY>1 AND ISNULL(B.MAXDPD,0)>0  AND B.NCIF_ASSETCLASSALT_KEY=1
WHERE A.EFFECTIVEFROMTIMEKEY<=27045  AND A.EFFECTIVETOTIMEKEY>=27045
--select EffectiveFromTimekey* from NPA_IntegrationDetails_After_18thProcess27045

SELECT A.* INTO #TEMP_2
FROM ReverseFeedDetails_After_18thProcess A INNER JOIN ReverseFeedDetails_After_19thProcess B
ON A.AccountNo=B.ACCOUNTNO--32
INNER JOIN #TEMP_DPD_0 C ON C.CUSTOMERACID=A.ACCOUNTNO
AND A.NatureofClassification IS NOT NULL--NPA IN 17TH
AND B.NatureofClassification IS NULL--UPGRADED IN 18TH


/*If account is std in 17th jan data and NPA in 18th jan data then we will check source asset class
for 17th jan data if it is STD then we will consider 18th jan RF as final,  */


SELECT B.CUSTOMERACID INTO #TEMP_DPD_0_DAY2 
FROM NPA_IntegrationDetails_After_18thProcess A 
INNER JOIN NPA_IntegrationDetails_After_19thProcess B 
 ON A.CUSTOMERACID=B.CUSTOMERACID--32
AND A.NCIF_ASSETCLASSALT_KEY=1 AND A.AC_ASSETCLASSALT_KEY=1 
 AND  B.NCIF_ASSETCLASSALT_KEY>1
WHERE A.EFFECTIVEFROMTIMEKEY<=27045  AND A.EFFECTIVETOTIMEKEY>=27045


--SELECT B.* INTO RF_5
SELECT B.*  INTO RF_5
FROM ReverseFeedDetails_After_19thProcess B
INNER JOIN #TEMP_DPD_0_DAY2 C
ON B.ACCOUNTNO=C.CUSTOMERACID
--AND A.NatureofClassification IS NOT NULL--NPA IN 17TH
--AND B.NatureofClassification IS NULL--UPGRADED IN 18TH
WHERE B.ACCOUNTNO NOT IN (SELECT ACCOUNTNO FROM #TEMP_1 )


/*If in 17th jan data, source asset class is NPA then we will check in 18th jan data,
dcco should be null or future date, dpd  should not be more than 90 
and exceptional flags should not be there then we will consider 
17th jan RF as final output or else will consider 18th jan RF as final */

SELECT		A.CUSTOMERACID 
INTO		#TEMP_MUL_DAY2 
FROM		NPA_IntegrationDetails_After_18thProcess A 
INNER JOIN	NPA_IntegrationDetails_After_19thProcess B 
ON			A.CUSTOMERACID=B.CUSTOMERACID--32
AND			A.AC_ASSETCLASSALT_KEY>1 AND A.NCIF_ASSETCLASSALT_KEY=1
AND			B.NCIF_ASSETCLASSALT_KEY>1
AND (
		 (B.DPD_StockStmt>180  AND ISNULL(B.PrincipleOutstanding,0)>0)
		OR (B.IsFraud='Y')
		OR (B.IsOTS='Y' )
	--OR (IsARC_Sale='Y' ) --COMMENTED BECAUSE SHOULD NOT IMPACT COBO 20240108
		OR (isnull(B.DCCO_Date,'2099-12-31')<@Ext_Date_2 AND B.PROJ_COMPLETION_DATE IS NULL)
		OR ((ISNULL(B.MaxDPD,0)>=91) )-- COMMENTED BY ZAIN 20231026
		OR (isnull(B.NatureofClassification,'')='C' AND B.AC_AssetClassAlt_Key<>1 )--AND DateofImpacting is not null) --20231017 by dev
)

SELECT B.* 
INTO RF_11
FROM #TEMP_MUL_DAY2 A INNER JOIN ReverseFeedDetails_After_19thProcess B
ON A.CUSTOMERACID=B.AccountNo



SELECT A.CUSTOMERACID INTO #TEMP_MUL_DAY1 FROM NPA_IntegrationDetails_After_18thProcess A 
INNER JOIN NPA_IntegrationDetails_After_19thProcess B 
ON A.CUSTOMERACID=B.CUSTOMERACID--32
AND A.AC_ASSETCLASSALT_KEY>1 AND A.NCIF_ASSETCLASSALT_KEY=1
AND B.NCIF_ASSETCLASSALT_KEY>1
AND NOT (
		 (B.DPD_StockStmt>180  AND ISNULL(B.PrincipleOutstanding,0)>0)
		OR (B.IsFraud='Y')
		OR (B.IsOTS='Y' )
	--OR (IsARC_Sale='Y' ) --COMMENTED BECAUSE SHOULD NOT IMPACT COBO 20240108
		OR (isnull(B.DCCO_Date,'2099-12-31')<@Ext_Date_2 AND B.PROJ_COMPLETION_DATE IS NULL)
		OR ((ISNULL(B.MaxDPD,0)>=91) )-- COMMENTED BY ZAIN 20231026
		OR (isnull(B.NatureofClassification,'')='C' AND B.AC_AssetClassAlt_Key<>1 )--AND DateofImpacting is not null) --20231017 by dev
)

SELECT B.* INTO RF_12
FROM #TEMP_MUL_DAY1 A INNER JOIN ReverseFeedDetails_After_18thProcess B
ON A.CUSTOMERACID=B.AccountNo




--------------------Sudesh/jaydev----------------------


SELECT b.CUSTOMERACID INTO #TEMP_MUL_DAY3 
FROM NPA_IntegrationDetails_After_18thProcess A 
INNER JOIN NPA_IntegrationDetails_After_19thProcess B 
ON A.CUSTOMERACID=B.CUSTOMERACID--32
AND A.AC_ASSETCLASSALT_KEY>1 AND A.NCIF_ASSETCLASSALT_KEY>1
AND B.NCIF_ASSETCLASSALT_KEY=1
AND NOT (
		 (B.DPD_StockStmt>180)  --AND ISNULL(B.PrincipleOutstanding,0)>0)
		OR (B.IsFraud='Y')
		OR (B.IsOTS='Y' )
	--OR (IsARC_Sale='Y' ) --COMMENTED BECAUSE SHOULD NOT IMPACT COBO 20240108
		OR (isnull(B.DCCO_Date,'2099-12-31')<@Ext_Date_2 AND B.PROJ_COMPLETION_DATE IS NULL)
		OR ((ISNULL(B.MaxDPD,0)>=91) )-- COMMENTED BY ZAIN 20231026
		OR (isnull(B.NatureofClassification,'')='C' )--AND DateofImpacting is not null) --20231017 by dev
)

SELECT B.* INTO RF_13
FROM #TEMP_MUL_DAY3 A INNER JOIN ReverseFeedDetails_After_19thProcess B
ON A.CUSTOMERACID=B.AccountNo

--COMPARING NPA_INTEGRATION DETAILS WITH THE CHANGED NATUREOFCLASSIFICATION
----UPDATE A SET A.NatureofClassification=B.NatureofClassification--UPDATED
--SELECT A.NatureofClassification,B.NatureofClassification,* 
--FROM NPA_IntegrationDetails A  
--INNER JOIN (SELECT * FROM RF_5 UNION SELECT * FROM RF_6 ) B 
--ON A.CustomerACID =B.ACCOUNTNO
--AND EffectiveFromTimeKey<=27046 AND EffectiveToTimeKey>=27046

/*COMMON AND UPGRADED ON 17 AND 18 --654*/
--SELECT A.*  INTO RF_8--DONE
SELECT A.*  INTO RF_8
FROM ReverseFeedDetails_After_18thProcess A INNER JOIN ReverseFeedDetails_After_19thProcess B
ON A.AccountNo=B.ACCOUNTNO
AND A.NatureofClassification IS  NULL--654
AND B.NatureofClassification IS  NULL--654


/*NON COMMON CASES IN 17 AND NOT IN 18 --3535*/
--SELECT A.*  INTO RF_9--DONE
SELECT A.*  INTO RF_9
FROM ReverseFeedDetails_After_18thProcess A 
WHERE  A.AccountNo NOT IN ( SELECT ACCOUNTNO FROM  ReverseFeedDetails_After_19thProcess B)--3535


/*NON COMMON CASES NOT IN 17 AND IN 18 --1262*/
--SELECT A.*  INTO RF_10
SELECT A.*  INTO RF_10
FROM ReverseFeedDetails_After_19thProcess A 
WHERE  A.AccountNo NOT IN ( SELECT ACCOUNTNO FROM  ReverseFeedDetails_After_18thProcess B)--1262


SELECT * 
INTO RF_FIN_17_18 
FROM RF_1
UNION 
SELECT * FROM RF_2
UNION
SELECT * FROM RF_3
UNION
SELECT * FROM RF_4
UNION
SELECT * FROM RF_5
UNION
SELECT * FROM RF_6
UNION
SELECT * FROM RF_7
UNION
SELECT * FROM RF_8
UNION
SELECT * FROM RF_9
UNION
SELECT * FROM RF_10
UNION
SELECT * FROM RF_11
UNION
SELECT * FROM RF_12
UNION
SELECT * FROM RF_13

/*FINAL CLUBBED RF FOR 17 AND 18*/
SELECT * FROM RF_FIN_17_18--SELECT 140561(COMMON CASES)+4797(NON COMMON CASES)=145358
--SELECT *  FROM RF_FIN_17_18 where AccountNo = '510003503304' and AsOnDate = '2024-01-17'

--;WITH CTE AS (SELECT *,row_number() OVER (paRTITION BY AccountNo ORDER BY AccountNo) AS rNK FROM	RF_FIN_17_18) select * from cte where Rnk > 1

--select AccountNO
--FROM		ReverseFeedDetails_After_18thProcess  
--UNION 
--select AccountNO
--FROM	ReverseFeedDetails_After_19thProcess

--except 
--select AccountNO from RF_FIN_17_18

--select AC_ASSETCLASSALT_KEY,DCCO_Date,* 
--from NPA_IntegrationDetails_After_18thProcess 
--WHERE cUSTOMERacID = '670080004742'
----where CustomerACID in ('845000006852','100133018016','670080004742','779830747106','570000009179','891000003065','510003483156','512003487820','803014032890','512003487936','617014004137','824014007686','824014031337','828013869351','832014026288','510003480483','891000003056','200005767513','822014027206','200001927461','518003406700','803014033057','200001927478','650005767501','832014028471','828013865850','832014034603','820014027567','816014013646','200999363623','589000002992')

--select ISNULL(MAXDPD,0),PrincipleOutstanding 
--,B.DPD_StockStmt,B.IsFraud,B.IsOTS,B.DCCO_Date,B.PROJ_COMPLETION_DATE,B.MaxDPD,B.NatureofClassification
--	--	OR (B.IsFraud='Y')
--	--	OR (B.IsOTS='Y' )
--	----OR (IsARC_Sale='Y' ) --COMMENTED BECAUSE SHOULD NOT IMPACT COBO 20240108
--	--	OR (isnull(B.DCCO_Date,'2099-12-31')<@Ext_Date_2 AND B.PROJ_COMPLETION_DATE IS NULL)
--	--	OR ((ISNULL(B.MaxDPD,0)>=91) )-- COMMENTED BY ZAIN 20231026
--	--	OR (isnull(B.NatureofClassification,'')='C' )--AND DateofImpacting is not null) --20231017 by dev
--from NPA_IntegrationDetails_After_19thProcess b
--WHERE cUSTOMERacID = '670080004742'
----where CustomerACID in ('845000006852','100133018016','670080004742','779830747106','570000009179','891000003065','510003483156','512003487820','803014032890','512003487936','617014004137','824014007686','824014031337','828013869351','832014026288','510003480483','891000003056','200005767513','822014027206','200001927461','518003406700','803014033057','200001927478','650005767501','832014028471','828013865850','832014034603','820014027567','816014013646','200999363623','589000002992')

--select * from #TEMP_MUL_DAY1 where CustomerACID in ('824014031337','803014032890')

--drop table RF_1
--drop table RF_2
--drop table RF_3
--drop table RF_4
--drop table RF_5
--drop table RF_6
--drop table RF_7
--drop table RF_8
--drop table RF_9
--drop table RF_10
--drop table RF_11
--drop table RF_12
GO