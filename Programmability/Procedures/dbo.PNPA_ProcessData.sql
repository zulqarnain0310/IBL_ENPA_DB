SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[PNPA_ProcessData]
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

/*UPDATE PNPA STATUS*/

UPDATE A
SET A.PNPA_Status='Y'
	,A.PNPA_ReasonAlt_Key=(CASE WHEN (AgriFlag='N'AND (@DAYS+ISNULL(A.MaxDPD,0))>90) OR (B.AgriFlag='Y' AND ((@DAYS+ISNULL(A.MaxDPD,0))>365))  THEN 
																		(CASE WHEN A.MaxDPD_Type=10 THEN 80 ---'DPD'
																				WHEN A.MaxDPD_Type=20 THEN (CASE WHEN C.CustomerACID IS NOT NULL AND C.MaxDPD=A.MaxDPD THEN 90 ELSE 50 END)---'DegradeByOverdue'    
																				WHEN A.MaxDPD_Type=30 THEN 10----'Interest Not Serviced'  
																				WHEN A.MaxDPD_Type=40 THEN 20---'Continue Access' 
																	     END   
																		   
																		) ELSE 40 END) ----'Renewals'
	
FROM NPA_IntegrationDetails A
INNER JOIN DimProduct       B   ON		(B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
									AND (A.ProductAlt_Key=B.ProductAlt_Key)

LEFT JOIN (SELECT CustomerACID,MAX(MaxDPD)MaxDPD FROM NPA_IntegrationBillDetails WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)GROUP BY CustomerACID) C  
ON C.CustomerACID=A.CustomerACID
																		

WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
		AND ISNULL(A.AuthorisationStatus,'A')='A'
		AND (A.AC_AssetClassAlt_Key=0 OR A.AC_AssetClassAlt_Key=1 OR A.AC_AssetClassAlt_Key IS NULL)      ---FILTER STD ACCOUNTS 
		AND  (ISNULL(A.AC_NPA_Date,'')='')
		AND (CASE WHEN B.AgriFlag='N' AND (((@DAYS+ISNULL(A.MaxDPD,0))>90) OR ((@DAYS+ISNULL(DPD_Renewals,0))>180)) THEN 1     ---NON AGRI
				        WHEN B.AgriFlag='Y' AND (((@DAYS+ISNULL(A.MaxDPD,0))>365) OR ((@DAYS+ISNULL(DPD_Renewals,0))>180)) THEN 1	   ---AGRI
				   END)=1
			

/*UPDATE PNPA STATUS*/

/*Update PNPA dt */

UPDATE A
SET A.PNPA_Date=CAST((CASE WHEN  B.AgriFlag='N' AND A.PNPA_ReasonAlt_Key=40 THEN (DATEADD(D,181,DATEADD(D,-A.DPD_Renewals,@ProcessingDt)))
					WHEN  B.AgriFlag='N' AND ISNULL(A.PNPA_ReasonAlt_Key,0) <>40 THEN (DATEADD(D,91,DATEADD(D,-A.MaxDPD,@ProcessingDt)))
					WHEN  B.AgriFlag='Y' AND A.PNPA_ReasonAlt_Key=40 THEN (DATEADD(D,181,DATEADD(D,-A.DPD_Renewals,@ProcessingDt)))
					WHEN B.AgriFlag='Y' AND ISNULL(A.PNPA_ReasonAlt_Key,0)<>40 THEN (DATEADD(D,366,DATEADD(D,-A.MaxDPD,@ProcessingDt)))
				 END )AS DATE)
FROM  NPA_IntegrationDetails A 
INNER JOIN DimProduct       B  ON	(B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
									AND (A.ProductAlt_Key=B.ProductAlt_Key)
WHERE (A.AC_AssetClassAlt_Key=0 OR A.AC_AssetClassAlt_Key=1 OR A.AC_AssetClassAlt_Key IS NULL)  
AND  (ISNULL(A.AC_NPA_Date,'')='') AND PNPA_Status='Y'


/*Update PNPA dt */





GO