SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

--EXEC [dbo].[PNPA_ProcessData_Processing] 24927
CREATE PROC [dbo].[PNPA_ProcessData_Processing]
@TimeKey  INT

AS 
--DECLARE
--@TimeKey  INT=24715

DECLARE
 @ProcessingDt  DATE
,@PNPA_Dt		DATE


SET @ProcessingDt=(SELECT MonthLastDate FROM SysDataMatrix WHERE CurrentStatus='C')  ----CURRENT PROCESSING DATE 
SET @PNPA_Dt=(SELECT EOMONTH(DATEADD(MONTH,1,@ProcessingDt)))   ----NEXT MONTH END DATE


DECLARE
@DAYS  INT 

/* Find Days difference between ProcessingDt and PNPA_Dt */

SELECT @DAYS=DATEDIFF(DAY,@ProcessingDt,@PNPA_Dt)

SELECT @DAYS,@ProcessingDt,@PNPA_Dt

DROP TABLE IF EXISTS #NCIF_ASSET
SELECT	    NCIF_Id
			,CustomerACID
			,CustomerId
			,AccountEntityID
			,ProductAlt_Key
			,AC_AssetClassAlt_Key
			,AC_NPA_Date
			,MaxDPD_Type
			,MaxDPD
			,DPD_Renewals
			,CAST(NULL AS CHAR(1))NEW_PNPA_Status
			,CAST(NULL AS VARCHAR(20)) NEW_PNPA_ReasonAlt_Key
			, CAST(NULL AS DATE)NEW_PNPA_Date
	INTO #NCIF_ASSET
	FROM NPA_IntegrationDetails
	WHERE (EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
	AND ISNULL(AC_AssetClassAlt_Key,'')<>'' 
	AND AC_AssetClassAlt_Key <>7  ----EXCLUDE  WRITE OFF
	AND ISNULL(ProductAlt_Key,0)<>3200    ----Exclude Write Off product as discusseda with Shihsir sir on 19/12/2017
	AND ISNULL(AuthorisationStatus,'A')='A'
	AND CASE        WHEN SrcSysAlt_Key = 10  AND CUSTOMER_IDENTIFIER = 'R' AND ( ISNULL(SanctionedLimit,0)<>0        
	                        OR ISNULL(DrawingPower,0)<>0 OR ISNULL(PrincipleOutstanding,0)<>0 OR ISNULL(BALANCE,0)<>0)  
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key = 10  AND CUSTOMER_IDENTIFIER = 'C'
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key = 20 AND ISNULL(ActualPrincipleOutstanding,0)<>0 AND ISNULL(Balance,0)<>0
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key = 60 AND ISNULL(PrincipleOutstanding,0)<>0 AND ISNULL(Balance,0)<>0
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key NOT IN (10, 20, 60)
	                                        THEN 1
	                        ELSE 0
	        END = 1


/*UPDATE PNPA STATUS*/


UPDATE A
SET A.NEW_PNPA_Status='Y'
	,A.NEW_PNPA_ReasonAlt_Key=(CASE WHEN (AgriFlag='N'AND (@DAYS+ISNULL(A.MaxDPD,0))>=90) OR (B.AgriFlag='Y' AND ((@DAYS+ISNULL(A.MaxDPD,0))>=365))  THEN 
																		(CASE WHEN A.MaxDPD_Type=10 THEN 80 ---'DPD'
																				WHEN A.MaxDPD_Type=20 THEN (CASE WHEN C.CustomerACID IS NOT NULL AND C.MaxDPD=A.MaxDPD THEN 90 ELSE 50 END)---'DegradeByOverdue'    
																				WHEN A.MaxDPD_Type=30 THEN 10----'Interest Not Serviced'  
																				WHEN A.MaxDPD_Type=40 THEN 20---'Continue Access' 
																	     END   
																		   
																		) ELSE 40 END) ----'Renewals'
	
FROM #NCIF_ASSET A
INNER JOIN DimProduct       B   ON		(B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
									AND (A.ProductAlt_Key=B.ProductAlt_Key)

LEFT JOIN (SELECT CustomerACID,MAX(MaxDPD)MaxDPD FROM NPA_IntegrationBillDetails 
			WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)GROUP BY CustomerACID) C  
ON C.CustomerACID=A.CustomerACID																	

WHERE  (A.AC_AssetClassAlt_Key=0 OR A.AC_AssetClassAlt_Key=1 OR A.AC_AssetClassAlt_Key IS NULL)      ---FILTER STD ACCOUNTS 
		AND  (ISNULL(A.AC_NPA_Date,'')='')
		AND (CASE WHEN B.AgriFlag='N' AND (((@DAYS+ISNULL(A.MaxDPD,0))>=90) OR ((@DAYS+ISNULL(DPD_Renewals,0))>=180)) THEN 1     ---NON AGRI
				        WHEN B.AgriFlag='Y' AND (((@DAYS+ISNULL(A.MaxDPD,0))>=365) OR ((@DAYS+ISNULL(DPD_Renewals,0))>=180)) THEN 1	   ---AGRI
				   END)=1
			


/*UPDATE PNPA STATUS*/

/*Update PNPA dt */


UPDATE A
SET A.NEW_PNPA_Date=CAST((CASE WHEN  B.AgriFlag='N' AND A.NEW_PNPA_ReasonAlt_Key=40		THEN (DATEADD(D,180,DATEADD(D,-A.DPD_Renewals,@ProcessingDt)))  --(DATEADD(D,181,DATEADD(D,-A.DPD_Renewals,@ProcessingDt)))
					WHEN  B.AgriFlag='N' AND ISNULL(A.NEW_PNPA_ReasonAlt_Key,0) <>40	THEN (DATEADD(D,90, DATEADD(D,-A.MaxDPD		 ,@ProcessingDt)))	--(DATEADD(D,91,DATEADD(D,-A.MaxDPD,@ProcessingDt)))
					WHEN  B.AgriFlag='Y' AND A.NEW_PNPA_ReasonAlt_Key=40				THEN (DATEADD(D,180,DATEADD(D,-A.DPD_Renewals,@ProcessingDt)))	--(DATEADD(D,181,DATEADD(D,-A.DPD_Renewals,@ProcessingDt)))
					WHEN B.AgriFlag='Y' AND ISNULL(A.NEW_PNPA_ReasonAlt_Key,0)<>40		THEN (DATEADD(D,365,DATEADD(D,-A.MaxDPD		 ,@ProcessingDt)))	--(DATEADD(D,366,DATEADD(D,-A.MaxDPD,@ProcessingDt)))
				 END )AS DATE)
FROM  #NCIF_ASSET A 
INNER JOIN DimProduct       B  ON	(B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
									AND (A.ProductAlt_Key=B.ProductAlt_Key)
WHERE (A.AC_AssetClassAlt_Key=0 OR A.AC_AssetClassAlt_Key=1 OR A.AC_AssetClassAlt_Key IS NULL)  
AND  (ISNULL(A.AC_NPA_Date,'')='') 
AND NEW_PNPA_Status='Y'

/*Update PNPA dt */

UPDATE A
SET PNPA_Status = NEW_PNPA_Status
	,PNPA_ReasonAlt_Key = B.NEW_PNPA_ReasonAlt_Key
	,PNPA_Date = B.NEW_PNPA_Date 
 FROM 
NPA_IntegrationDetails A
INNER JOIN #NCIF_ASSET B
	ON A.EffectiveFromTimeKey <= @TimeKey AND EffectiveToTimeKey >= @TimeKey
	AND A.NCIF_Id = B.NCIF_Id
	AND A.CustomerId = B.CustomerId
	AND A.CustomerACID = B.CustomerACID
	AND A.AccountEntityID = B.AccountEntityID





GO