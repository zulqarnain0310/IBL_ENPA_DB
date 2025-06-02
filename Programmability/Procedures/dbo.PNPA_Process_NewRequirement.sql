SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[PNPA_Process_NewRequirement]

AS

DECLARE 
 @ProcessingDt  DATE 
,@PNPA_Dt	 DATE
,@Days        INT
,@TimeKey     INT=24745

SET @ProcessingDt=(SELECT MonthLastDate FROM SysDataMatrix WHERE CurrentStatus='C')
SET @PNPA_Dt=(SELECT DATEADD(MONTH,1,@ProcessingDt))   ----NEXT MONTH END DATE
SET @DAYS=(SELECT DATEDIFF(DAY,@ProcessingDt,@PNPA_Dt))


      UPDATE A
         SET A.PNPA_Status='Y'
         	,A.PNPA_ReasonAlt_Key=(CASE WHEN (AgriFlag='N'AND (@DAYS+ISNULL(A.MaxDPD,0))>90) OR (B.AgriFlag='Y' AND ((@DAYS+ISNULL(A.MaxDPD,0))>365))  THEN 
							(CASE WHEN A.MaxDPD_Type=10 THEN 80 ---'DPD'
									WHEN A.MaxDPD_Type=20 THEN (CASE WHEN C.CustomerACID IS NOT NULL AND C.MaxDPD=A.MaxDPD THEN 90 ELSE 50 END)---'DegradeByOverdue'   
									WHEN A.MaxDPD_Type=30 THEN 10----'Interest Not Serviced'  
									WHEN A.MaxDPD_Type=40 THEN 20---'Continue Access' 
						     END   
							   
							) END ) 
       FROM NPA_IntegrationDetails A

         INNER JOIN DimProduct       B   ON		(B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
         									AND (A.ProductAlt_Key=B.ProductAlt_Key)
            
         LEFT JOIN (SELECT CustomerACID,MAX(MaxDPD)MaxDPD FROM NPA_IntegrationBillDetails WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)GROUP BY CustomerACID) C  
                                         ON C.CustomerACID=A.CustomerACID
         									
           WHERE ISNULL(A.AuthorisationStatus,'A')='A'
                 		  AND (A.AC_AssetClassAlt_Key=0 OR A.AC_AssetClassAlt_Key=1 OR A.AC_AssetClassAlt_Key IS NULL)
                          AND (ISNULL(A.AC_NPA_Date, '') = '')
                          AND (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
		              AND CASE WHEN B.AgriFlag='N' AND ((@Days+ISNULL(A.MaxDPD,0))>90)    THEN 1  
							   WHEN B.AgriFlag='Y' AND ((@Days+ISNULL(A.MaxDPD,0))>365)  THEN 1 END=1
				
 
		UPDATE A
        SET A.PNPA_Date=CAST((CASE 
        						WHEN  B.AgriFlag='N' AND ISNULL(A.PNPA_ReasonAlt_Key,0) <>40 THEN (DATEADD(D,91,DATEADD(D,-A.MaxDPD,CAST(@ProcessingDt AS DATE))))
        						WHEN B.AgriFlag='Y' AND ISNULL(A.PNPA_ReasonAlt_Key,0)<>40 THEN (DATEADD(D,366,DATEADD(D,-A.MaxDPD,CAST(@ProcessingDt AS DATE))))
        				 END )AS DATE)
        FROM  NPA_IntegrationDetails A 

        INNER JOIN DimProduct       B  ON	(B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
               									AND (A.ProductAlt_Key=B.ProductAlt_Key)
               WHERE (A.AC_AssetClassAlt_Key=0 OR A.AC_AssetClassAlt_Key=1 OR A.AC_AssetClassAlt_Key IS NULL)  
               AND  (ISNULL(A.AC_NPA_Date,'')='') AND PNPA_Status='Y';


 /*  Update the PNPA_ReasonAlt_Key again if pnpa happend because of DPD Renewals */

		UPDATE A
		SET A.PNPA_Status='Y'
		   ,A.PNPA_ReasonAlt_Key=CASE WHEN ISNULL(A.PNPA_ReasonAlt_Key,'')='' THEN '40' ELSE A.PNPA_ReasonAlt_Key+','+'40' END
		   ,A.NF_PNPA_Date=(DATEADD(D,181,DATEADD(D,-A.DPD_Renewals,CAST(@ProcessingDt AS DATE))))
	    FROM NPA_IntegrationDetails	A
		INNER JOIN 	DimProduct       B   ON		(B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
         									AND (A.ProductAlt_Key=B.ProductAlt_Key)
		WHERE     (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
			  AND ISNULL(A.AuthorisationStatus,'A')='A'
			  AND (A.AC_AssetClassAlt_Key=0 OR A.AC_AssetClassAlt_Key=1 OR A.AC_AssetClassAlt_Key IS NULL)
			  AND (ISNULL(A.AC_NPA_Date, '') = '')
			  AND (@Days+ISNULL(A.DPD_Renewals,0))>180										



       
GO