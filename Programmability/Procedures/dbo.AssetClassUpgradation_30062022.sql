SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

--EXEC [dbo].[AssetClassUpgradation] 26084
Create PROC [dbo].[AssetClassUpgradation_30062022](@TIMEKEY  INT)
WITH RECOMPILE
AS 

-- VCS here pro schema is being used but not in degradation, need to decide about the schema.
--- VCS Changed variable names for better understanding, the code need to be amended accordingly.
------Changed on 14-06-2021 in variables and businessrule logic ----------------
DECLARE @OverdueRefDPD INT=(SELECT RefValue FROM RefPeriod WHERE EffectiveFromTimeKey<=@TImeKey AND EffectiveToTimeKey>=@TimeKey AND BusinessRule='Refperiodoverdueupg')
,@ContiExcessREdDPD INT=(SELECT RefValue FROM RefPeriod WHERE EffectiveFromTimeKey<=@TImeKey AND EffectiveToTimeKey>=@TimeKey AND BusinessRule='Refperiodoverdrawnupg')
,@IntNotServiceRefDPD INT=(SELECT RefValue FROM RefPeriod WHERE EffectiveFromTimeKey<=@TImeKey AND EffectiveToTimeKey>=@TimeKey AND BusinessRule='Refperiodintserviceupg')
,@StkStamentRedDPD INT=(SELECT RefValue FROM RefPeriod WHERE EffectiveFromTimeKey<=@TImeKey AND EffectiveToTimeKey>=@TimeKey AND BusinessRule='Refperiodstkstatementupg')
,@RenewalDueRefDPD INT=(SELECT RefValue FROM RefPeriod WHERE EffectiveFromTimeKey<=@TImeKey AND EffectiveToTimeKey>=@TimeKey AND BusinessRule='Refperiodreviewupg')
,@Processingdate DATE=(SELECT DATE 
             FROM SysDataMatrix --- VCS: SysDatamatrix to be used, instead of @date variable as @Processingdate would be more indicative.
			 WHERE TimeKey=@TIMEKEY)
DECLARE @STD_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key 
                               FROM DimAssetClass 
                               WHERE EffectiveFromTimeKey<=@TIMEKEY 
							     AND EffectiveToTimeKey>=@TIMEKEY 
								 AND AssetClassShortNameEnum='STD')
DECLARE @WO_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key 
                               FROM DimAssetClass 
                               WHERE EffectiveFromTimeKey<=@TIMEKEY 
							     AND EffectiveToTimeKey>=@TIMEKEY 
								 AND AssetClassShortNameEnum='WO')

DECLARE @LOS_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key
                               FROM DimAssetClass 
                               WHERE EffectiveFromTimeKey<=@TIMEKEY 
							     AND EffectiveToTimeKey>=@TIMEKEY 
								 AND AssetClassShortNameEnum='LOS')

								 DECLARE @Others_Jun19 INT=(SELECT ParameterAlt_Key FROM   DimParameter WHERE EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey AND DimParameterName='TypeofRestructuring' AND ParameterName='Others_Jun19')
BEGIN TRY
DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='AssetClassUpgradation' AND [EXT_DATE]=@Processingdate AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]
           ([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @Processingdate,@TimeKey,'AssetClassUpgradation',GETDATE()
BEGIN TRAN


IF OBJECT_ID('TEMPDB..#NCIF_ASSET') IS NOT NULL
DROP TABLE #NCIF_ASSET
BEGIN	
SELECT DISTINCT	 A.NCIF_Id
		,CustomerId
		,CustomerACID
		,DPD_Overdue_Loans
		,DPD_Overdrawn
		,IsCentral_GovGty
		,GtyRepudiated
		,DPD_Interest_Not_Serviced
		,DPD_StockStmt
		,DPD_Renewals
		,CAST(NULL AS VARCHAR(1)) FlgUpg
    INTO #NCIF_ASSET
	FROM NPA_IntegrationDetails A 
	LEFT JOIN [CurDat].AdvAcRestructureDetail RES ON RES.EffectiveFromTimeKey<=@TIMEKEY 
	                                             AND RES.EffectiveToTimeKey>=@TIMEKEY
	                                             AND A.CustomerId=RES.RefCustomerId
										         AND A.CustomerACID=RES.RefSystemAcId
	WHERE A.EffectiveFromTimeKey<=@TIMEKEY 
	AND A.EffectiveToTimeKey>=@TIMEKEY
	AND ISNULL(AC_AssetClassAlt_Key,'')<>'' 
	AND A.AC_Closed_Date IS NULL
	AND AC_AssetClassAlt_Key <>@WO_Alt_Key  ----EXCLUDE  WRITE OFF
	/*Exclude NCIF if it is having write off or Restructured  Account*/
	AND Not Exists (Select 1 from NPA_IntegrationDetails NID 
	                Where NID.EffectiveFromTimeKey<=@Timekey -- With this condition, above condition to be reviewed
                      And NID.EffectiveToTimeKey>=@Timekey
                      And (ISNULL(WriteOffFlag,'N')='Y'
					  OR ISNULL(IsFraud,'N')='Y'
					  OR /*(ISNULL(DCCO_Date,'2099-01-01')<@Processingdate AND PROJ_COMPLETION_DATE IS NULL)--added on 09-08-2021 for DCCO date*/
					  (CASE WHEN PROJ_COMPLETION_DATE IS NOT NULL 
					             THEN 'N'
					        ELSE (CASE WHEN ISNULL(DCCO_Date,'2099-01-01')<@Processingdate THEN 'Y' ELSE 'N' END)
                        END)='Y' --Project completion date is added on 12-09-2021
					  OR ISNULL(DCCO_Date,'2099-01-01')<@Processingdate --added on 09-08-2021 for DCCO date
					  OR ISNULL(IsOTS,'N')='Y'       ------Added on 16-06-2021 by Sunil 
					  OR ISNULL(IsSuitFiled,'N')='Y'       ------Added on 16-06-2021 by Sunil 
					  OR ISNULL(IsARC_Sale,'N')='Y'       ------Added on 16-06-2021 by Sunil 
					  OR (CASE WHEN ISNULL(A.IsRestructured,'N')='Y' 
					                THEN (CASE WHEN ((A.AC_NPA_Date>'2021-03-31'
                                                AND A.AC_NPA_Date<RES.RestructureDt
												AND RES.RestructureTypeAlt_Key IN(SELECT ParameterAlt_Key 
												                                    FROM DimParameter
                                                                                   WHERE DimParameterName='TypeofRestructuring'
                                                                                     AND ParameterName IN('MSME-May21', 'Ind.Business-May21', 'SmallBusiness-May21', 'PL-May21','MSME-Aug20-Extn-May21','Corporate-Aug20-Extn-May21')
																					 
																					 )) 
																					 
																					 OR 
																					/* (A.SancDate >=@Processingdate 
                                                --AND Res.RestructureDt>='2021-04-01' And Res.RestructureDt<='2021-12-31'--Commented by sunil on 23/08/2021
												and */ (RES.RestructureTypeAlt_Key IN(SELECT ParameterAlt_Key 
												                                    FROM DimParameter
                                                                                   WHERE DimParameterName='TypeofRestructuring'
                                                                                     AND ParameterName IN('Ind.Business-Aug20-May21','SmallBusiness-Aug20-May21','PL-Aug20-May21')
																					 
																					 ))
																					 
																					 )
												    THEN 'N'
								              		 WHEN Res.RestructureTypeAlt_Key=@Others_Jun19 
											        AND (ISNULL((CASE WHEN ISNULL(RES.TEN_PC_DATE,'1900-01-01')> DATEADD(YEAR,1,ISNULL(Res.RepaymentStartDate,'1900-01-01'))
                                                                           THEN RES.TEN_PC_DATE
								                                      ELSE DATEADD(YEAR,1,ISNULL(Res.RepaymentStartDate,'1900-01-01'))
							                                      END),RES.RestructureDt)<=@Processingdate)--TEN_PC_DATE is added on 12-09-2021
								               -- AND ISNULL(RES.RestructureDt,'1900-01-01')<>@Processingdate
								                    THEN 'N'
										  WHEN DATEADD(YEAR,1,ISNULL(RES.RepaymentStartDate,RES.RestructureDt))<=@Processingdate
								               -- AND ISNULL(RES.RestructureDt,'1900-01-01')<>@Processingdate
								                    THEN 'N'
								          ELSE 'Y' 
									END)
								ELSE 'N'
							END)='Y'
					  OR AC_AssetClassAlt_Key=@LOS_Alt_Key)
                          AND NID.NCIF_Id=A.NCIF_Id)
    /*Exclude NCIF if its all accounts are STD*/
	AND NOT Exists (SELECT 1 
	                FROM NPA_IntegrationDetails NID
	                INNER JOIN DimAssetClass DAC ON NID.EffectiveFromTimeKey<=@TIMEKEY
					                            AND NID.EffectiveToTimeKey>=@TIMEKEY
												AND DAC.EffectiveFromTimeKey<=@TIMEKEY
					                            AND DAC.EffectiveToTimeKey>=@TIMEKEY
												AND NID.AC_AssetClassAlt_Key=DAC.AssetClassAlt_Key
												AND NID.NCIF_Id=A.NCIF_Id
                    GROUP BY NCIF_ID
                    HAVING COUNT(AC_AssetClassAlt_Key)=SUM(CASE WHEN AssetClassShortNameEnum='STD' THEN 1 ELSE 0 END ))
	
CREATE NONCLUSTERED INDEX NCI_NCIF_ASSET ON #NCIF_ASSET(NCIF_Id)

UPDATE #NCIF_ASSET SET FlgUpg='Y'
WHERE  ISNULL(DPD_Overdue_Loans,0)<=@OverdueRefDPD
AND ISNULL(DPD_Overdrawn,0)<=@ContiExcessREdDPD
AND ISNULL(DPD_Interest_Not_Serviced,0)<=@IntNotServiceRefDPD
AND ISNULL(DPD_StockStmt,0)<=@StkStamentRedDPD
AND ISNULL(DPD_Renewals,0)<=@RenewalDueRefDPD
AND (CASE WHEN IsCentral_GovGty='Y' 
               THEN (CASE WHEN GtyRepudiated='Y'
			                   THEN 0
					      ELSE 1
					 END)
               ELSE 1
      END)=1


IF OBJECT_ID('TEMPDB..#Temp') IS NOT NULL
DROP TABLE #Temp

SELECT A.NCIF_Id,COUNT(DISTINCT A.CustomerACID) COUNT
INTO #Temp
FROM NPA_IntegrationDetails A
INNER JOIN #NCIF_ASSET B ON A.EffectiveFromTimeKey<=@TIMEKEY    
                         AND A.EffectiveToTimeKey>=@TIMEKEY
						 AND A.NCIF_Id=B.NCIF_Id
						 AND A.AC_Closed_Date IS NULL
GROUP BY A.NCIF_Id


UPDATE A SET NCIF_AssetClassAlt_Key=@STD_Alt_Key,NCIF_NPA_Date=NULL,FlgUpg='Y',UpgDate=@Processingdate
FROM NPA_IntegrationDetails A
INNER JOIN (SELECT NCIF_Id,SUM(CASE WHEN FlgUpg='Y' THEN 1 ELSE 0 END) COUNT
           FROM #NCIF_ASSET
           GROUP BY NCIF_Id) B ON A.EffectiveFromTimeKey<=@TIMEKEY
		                          AND A.EffectiveToTimeKey>=@TIMEKEY
		                          AND A.NCIF_Id=B.NCIF_Id
INNER JOIN #Temp C ON C.NCIF_Id=A.NCIF_Id
WHERE B.Count=C.COUNT
AND  A.AC_Closed_Date IS NULL

DROP TABLE #NCIF_ASSET
DROP TABLE #Temp
END

--UPDATE Audit Flag

COMMIT TRAN
UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='AssetClassUpgradation' AND [EXT_DATE]=@Processingdate AND ISNULL([Audit_Flg],0)=0
END TRY
BEGIN CATCH
 DECLARE
   @ErMessage NVARCHAR(2048),
   @ErSeverity INT,
   @ErState INT
 
 SELECT  @ErMessage = ERROR_MESSAGE(),
   @ErSeverity = ERROR_SEVERITY(),
   @ErState = ERROR_STATE()

UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET ERROR_MESSAGE=@ErMessage  
WHERE [SP_Name]='AssetClassUpgradation' AND [EXT_DATE]=@Processingdate AND ISNULL([Audit_Flg],0)=0
 
 RAISERROR (@ErMessage,
             @ErSeverity,
             @ErState )
ROLLBACK TRAN
END CATCH
GO