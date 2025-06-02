SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROC [dbo].[AssetClassUpgradation_20230807](@TIMEKEY  INT)
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

exec [dbo].[RestructureProcess]  @TimeKey  /* 17062023 - RESTRUCTURE DEPLOYMENT */

Drop table if exists #NPA_IntegrationDetails
Select  NCIF_Id
,EffectiveFromTimeKey
,EffectiveToTimeKey
,CustomerACID
,IsRestructured
,CustomerId
,DPD_Overdue_Loans
,DPD_Overdrawn
,IsCentral_GovGty
,GtyRepudiated
,DPD_Interest_Not_Serviced
,DPD_StockStmt
,DPD_Renewals
,AC_AssetClassAlt_Key
,AC_Closed_Date
,WriteOffFlag
,IsFraud
,PROJ_COMPLETION_DATE
,DCCO_Date
,IsOTS
,IsSuitFiled
,IsARC_Sale
,AC_NPA_Date
,SancDate
,NCIF_AssetClassAlt_Key
,NCIF_NPA_Date
,UpgDate
,MaxDPD --17062023 -- added for restructure
into #NPA_IntegrationDetails from NPA_IntegrationDetails
where EffectiveFromTimeKey<=@TIMEKEY  and EffectiveToTimeKey>=@TIMEKEY

CREATE NONCLUSTERED INDEX idx_NPA_IntegrationDetail_temp ON #NPA_IntegrationDetails(CustomerACID)

Drop table if exists #AdvAcRestructureDetail
Select 
RefSystemAcId
,EffectiveFromTimeKey
,EffectiveToTimeKey
,RefCustomerId
,RestructureTypeAlt_Key
,RestructureDt
,TEN_PC_DATE
,RepaymentStartDate
 into #AdvAcRestructureDetail 
 from [CurDat].AdvAcRestructureDetail
where EffectiveFromTimeKey<=@TIMEKEY  and EffectiveToTimeKey>=@TIMEKEY

CREATE NONCLUSTERED INDEX idx_AdvAcRestructureDetail_temp ON #AdvAcRestructureDetail(RefSystemAcId)


/* Added By Satish as temp table checking of restructure data as on date 26092022 */
IF OBJECT_ID('TEMPDB..#Restructured_NCIF_Id') IS NOT NULL
DROP TABLE #Restructured_NCIF_Id

/* start - 17062023 - for restructure deployment - new logic impelemted for restructure upgrade below.  EARLIER WHILE NEW MODULE WAS UNDER DEVELOPMENT RESTRUCTURE UPGRADE WAS RESTRUCTED
--SELECT NPA.NCIF_Id into #Restructured_NCIF_Id
--	                FROM #NPA_IntegrationDetails NPA
--						INNER JOIN #AdvAcRestructureDetail RES
--							ON RES.EffectiveFromTimeKey<=@TIMEKEY  AND RES.EffectiveToTimeKey>=@TIMEKEY
--							AND NPA.EffectiveFromTimeKey<=@TIMEKEY  AND NPA.EffectiveToTimeKey>=@TIMEKEY
--							AND RES.RefSystemAcId=NPA.CustomerACID   --------  changed by satish as on date 22092022 as accountentityid was null
--							AND NPA.IsRestructured='Y'
--						INNER JOIN DimParameter PAR
--							ON PAR.EffectiveFromTimeKey<=@TIMEKEY  AND PAR.EffectiveToTimeKey>=@TIMEKEY
--							AND ParameterAlt_Key=RES.RestructureTypeAlt_Key
--							AND DimParameterName='TypeofRestructuring'
--                            AND ParameterShortNameEnum NOT IN('Natural Calamity')
end - 17062023 - for restructure deployment - new logic impelemted for restructure upgrade below    */
  
 /* START - 17062023 - RESTRUCTURE DEPLOYMENT */
  SELECT NPA.NCIF_Id  
  
  
	into #Restructured_NCIF_Id
	                FROM #NPA_IntegrationDetails NPA
						INNER JOIN AdvAcRestructureCal RES
							ON RES.EffectiveFromTimeKey<=@TIMEKEY  AND RES.EffectiveToTimeKey>=@TIMEKEY
							AND NPA.EffectiveFromTimeKey<=@TIMEKEY  AND NPA.EffectiveToTimeKey>=@TIMEKEY
							AND RES.CustomerACID=NPA.CustomerACID   --------  changed by satish as on date 22092022 as accountentityid was null
							AND NPA.IsRestructured='Y'
						    INNER JOIN DimParameter PAR
							ON PAR.EffectiveFromTimeKey<=@TIMEKEY  AND PAR.EffectiveToTimeKey>=@TIMEKEY
							AND ParameterAlt_Key=RES.RestructureTypeAlt_Key
							AND DimParameterName='TypeofRestructuring'
                            AND ParameterShortNameEnum NOT IN('Natural Calamity')
							and (CASE WHEN ISNULL(NPA.IsRestructured,'N')='Y' 
								THEN		
									( CASE  WHEN ISNULL(ParameterShortNameEnum,'') IN('Natural Calamity','Others_COMGT') AND ISNULL(NPA.MaxDPD,0)=0 --Natural Clamity/Change of Management
													THEN  'N' 
											WHEN ISNULL(ParameterShortNameEnum,'') IN( /*-------MSME Restructuring */
																						'MSME-Aug20-Extn-May21','MSME-Aug20','MSME-May21')
														 AND ISNULL(NPA.MaxDPD,0)=0 
														 AND ISNULL(RES.SP_ExpiryExtendedDate,RES.SP_ExpiryDate)<@Processingdate
														
													THEN 'N'
											WHEN ISNULL(ParameterShortNameEnum,'') IN('DCCO') /*'DCCO'*/
																					--AND RES.ZeroDPD_Date IS NOT NULL	-- commented by satish as on date 19122022
																					AND ISNULL(NPA.MaxDPD,0)=0 
																					AND DCCO_DATE IS NOT NULL AND TEN_PC_DATE IS NOT NULL
																					AND ISNULL(RES.SP_ExpiryExtendedDate,RES.SP_ExpiryDate)<@Processingdate
													THEN 'N'
											when 	ISNULL(ParameterShortNameEnum,'') in /*Covid-19 OTR Personal Loan, Business Loand and Individual Business */
																						('PL-Aug20','Ind.Business-May21','SmallBusiness-May21','PL-May21','Ind.Business-Aug20-May21','SmallBusiness-Aug20-May21','PL-Aug20-May21')
														 AND ISNULL(NPA.MaxDPD,0)=0 and TEN_PC_DATE IS NOT NULL
														 AND ISNULL(RES.SP_ExpiryExtendedDate,RES.SP_ExpiryDate)<@Processingdate
														 then 'N'

											WHEN  ISNULL(ParameterShortNameEnum,'') IN( /*Covid-19 Other than Personal Loan */
																						'Corporate-Aug20-Extn-May21','Corporate-Aug20'
																						/* Under Irac/Normal Restrucuture Under Irac */
																						,'Others','Others_Jun19')
														-- AND RES.ZeroDPD_Date IS NOT NULL   -- commented by satish as on date 19122022
														 AND ISNULL(NPA.MaxDPD,0)=0 and TEN_PC_DATE IS NOT NULL
														 AND ISNULL(RES.SP_ExpiryExtendedDate,RES.SP_ExpiryDate)<@Processingdate
														 AND SecondRestrDate IS Not Null
														 AND  ((AggregateExposure  in('100 CR to Less than 500 CR') AND CreditRating1 in('AAA+','AAA','AAA-','AA+','AA','AA-','BBB+','BBB','BBB-'))
															          OR (AggregateExposure  in('Equal to or Greater than 500 CR') and  CreditRating1 in('AAA+','AAA','AAA-','AA+','AA','AA-','BBB+','BBB','BBB-') 
																				AND  CreditRating2 in('AAA+','AAA','AAA-','AA+','AA','AA-','BBB+','BBB','BBB-'))
																	 OR  (AggregateExposure  in('Less than 100 Cr') )
															  )
															  
													THEN 'N'
											
											ELSE 'Y'
										END) 	END)='Y'
          
  CREATE NONCLUSTERED INDEX idx_Restructured_NCIF_Id ON #Restructured_NCIF_Id(NCIF_Id)
  /* END - 17062023 - RESTRUCTURE DEPLOYMENT */
  
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
	FROM #NPA_IntegrationDetails A 
	LEFT JOIN #AdvAcRestructureDetail RES ON RES.EffectiveFromTimeKey<=@TIMEKEY 
	                                             AND RES.EffectiveToTimeKey>=@TIMEKEY
	                                             AND A.CustomerId=RES.RefCustomerId
										         AND A.CustomerACID=RES.RefSystemAcId
	WHERE A.EffectiveFromTimeKey<=@TIMEKEY 
	AND A.EffectiveToTimeKey>=@TIMEKEY
	AND ISNULL(AC_AssetClassAlt_Key,'')<>'' 
	AND A.AC_Closed_Date IS NULL
	AND AC_AssetClassAlt_Key <>@WO_Alt_Key  ----EXCLUDE  WRITE OFF
	/*Exclude NCIF if it is having write off or Restructured  Account*/
	AND Not Exists (Select 1 from #NPA_IntegrationDetails NID 
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
/* COMMENTED RESSTR UPG CODE -- CODE COMMENTED ON 26092022 FOR RESTRICTING UPGRADATION WHILE NEW MODULE WAS UNDER DEVELOPMENT. FOR RESTRUCTNG NEW CODE ASS ADDED IN THE BEGINING OF SP */
					  ----OR (CASE WHEN ISNULL(A.IsRestructured,'N')='Y' 
					  ----              THEN (CASE WHEN 
							----					RES.RestructureTypeAlt_Key IN(SELECT ParameterAlt_Key 
							----					                                    FROM DimParameter
       ----                                                                            WHERE DimParameterName='TypeofRestructuring'
       ----                                                                              AND ParameterShortNameEnum  IN('Natural Calamity')
																					 
							----									) 
							----				THEN 'Y'
							----			ELSE 'N' END)
	
					   --             THEN (CASE WHEN ((A.AC_NPA_Date>'2021-03-31'
        --                                        AND A.AC_NPA_Date<RES.RestructureDt
								--				AND RES.RestructureTypeAlt_Key IN(SELECT ParameterAlt_Key 
								--				                                    FROM DimParameter
        --                                                                           WHERE DimParameterName='TypeofRestructuring'
        --                                                                             AND ParameterName IN('MSME-May21', 'Ind.Business-May21', 'SmallBusiness-May21', 'PL-May21','MSME-Aug20-Extn-May21','Corporate-Aug20-Extn-May21')
																					 
								--													 )) 
																					 
								--													 OR 
								--													/* (A.SancDate >=@Processingdate 
        --                                        --AND Res.RestructureDt>='2021-04-01' And Res.RestructureDt<='2021-12-31'--Commented by sunil on 23/08/2021
								--				and */ (RES.RestructureTypeAlt_Key IN(SELECT ParameterAlt_Key 
								--				                                    FROM DimParameter
        --                                                                           WHERE DimParameterName='TypeofRestructuring'
        --                                                                             AND ParameterName IN('Ind.Business-Aug20-May21','SmallBusiness-Aug20-May21','PL-Aug20-May21')
																					 
								--													 ))
																					 
								--													 )
								--				    THEN 'N'
								--              		 WHEN Res.RestructureTypeAlt_Key=@Others_Jun19 
								--			        AND (ISNULL((CASE WHEN ISNULL(RES.TEN_PC_DATE,'1900-01-01')> DATEADD(YEAR,1,ISNULL(Res.RepaymentStartDate,'1900-01-01'))
        --                                                                   THEN RES.TEN_PC_DATE
								--                                      ELSE DATEADD(YEAR,1,ISNULL(Res.RepaymentStartDate,'1900-01-01'))
							 --                                     END),RES.RestructureDt)<=@Processingdate)--TEN_PC_DATE is added on 12-09-2021
								--               -- AND ISNULL(RES.RestructureDt,'1900-01-01')<>@Processingdate
								--                    THEN 'N'
								--		  WHEN DATEADD(YEAR,1,ISNULL(RES.RepaymentStartDate,RES.RestructureDt))<=@Processingdate
								--               -- AND ISNULL(RES.RestructureDt,'1900-01-01')<>@Processingdate
								--                    THEN 'N'
								--          ELSE 'Y' 
								--	END)
								--ELSE 'N'
							----END)='Y'
				/* END OF RESTR CODE COMMENTED */

					  OR (AC_AssetClassAlt_Key=@LOS_Alt_Key AND ISNULL(IsFraud,'Y')='Y'))
                          AND NID.NCIF_Id=A.NCIF_Id)
	/* ADDED NEW CODE FOR RESTR ACCOUNT NOT UPGRADE N CASE RESTRUCTIRE NO MARKED AS NATURAL CALAMITY */
         --	AND NOT Exists (SELECT NPA.NCIF_Id   /* this code commented by satish as on date 26092022 */
	       --        FROM #NPA_IntegrationDetails NPA
			--			INNER JOIN [CurDat].AdvAcRestructureDetail RES
					--		ON RES.EffectiveFromTimeKey<=@TIMEKEY  AND RES.EffectiveToTimeKey>=@TIMEKEY
					--		AND NPA.EffectiveFromTimeKey<=@TIMEKEY  AND NPA.EffectiveToTimeKey>=@TIMEKEY
					--		AND RES.RefSystemAcId=NPA.CustomerACID   --------  changed by satish as on date 22092022 as accountentityid was null
					--		AND NPA.IsRestructured='Y'
					--	INNER JOIN DimParameter PAR
					--		ON PAR.EffectiveFromTimeKey<=@TIMEKEY  AND PAR.EffectiveToTimeKey>=@TIMEKEY
					--		AND ParameterAlt_Key=RES.RestructureTypeAlt_Key
					--		AND DimParameterName='TypeofRestructuring'
                           -- AND ParameterShortNameEnum NOT IN('Natural Calamity')
			--		 AND NPA.NCIF_Id=A.NCIF_Id)
 /* commented by satish as on 29092022 as from restructure it will be deleted down */
	---and a.NCIF_Id not in (Select NCIF_Id from #Restructured_NCIF_Id)  ---- /* This code added by satish as on date 26092022 to use temp restructure table given above*/

    /*Exclude NCIF if its all accounts are STD*/
	AND NOT Exists (SELECT 1 
	                FROM #NPA_IntegrationDetails NID
	                INNER JOIN DimAssetClass DAC ON NID.EffectiveFromTimeKey<=@TIMEKEY
					                            AND NID.EffectiveToTimeKey>=@TIMEKEY
												AND DAC.EffectiveFromTimeKey<=@TIMEKEY
					                            AND DAC.EffectiveToTimeKey>=@TIMEKEY
												AND NID.AC_AssetClassAlt_Key=DAC.AssetClassAlt_Key
												AND NID.NCIF_Id=A.NCIF_Id
                    GROUP BY NCIF_ID
                    HAVING COUNT(AC_AssetClassAlt_Key)=SUM(CASE WHEN AssetClassShortNameEnum='STD' THEN 1 ELSE 0 END ))
	
	CREATE NONCLUSTERED INDEX NCI_NCIF_ASSET ON #NCIF_ASSET(NCIF_Id)
	
 /* Added by satish as 29092022 to delete the restructured accounts from #NCIF_ASSET table */
 	DELETE FROM #NCIF_ASSET WHERE NCIF_Id IN (SELECT NCIF_Id FROM #Restructured_NCIF_Id)

UPDATE #NCIF_ASSET SET FlgUpg='N'  /* 17062023 - for restructure deployment - */
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
FROM #NPA_IntegrationDetails A
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

  /* Added this code to on 09052023 by satish to update the standard accounts dbt and other flag */
  UPDATE NPA_IntegrationDetails set FlgErosion=null,
  DbtDT =null,LossDT=nULL,ErosionDT=NULL  
  where NCIF_AssetClassAlt_Key=1 
  and EffectiveFromTimeKey<=@TIMEKEY
  and EffectiveToTimeKey>=@TIMEKEY
/* start - 17062023 - for restructure deployment */

/* UPDATE FINAL ASSET CLASS IN [AdvAcRestructureCal] TABLE AFTER UPGRADE PROCESS */
Update A SET             
		   A.FinalAssetClassAlt_Key=b.NCIF_AssetClassAlt_Key            
		  ,A.FinalNpaDt=b.NCIF_NPA_Date            
	FROM [AdvAcRestructureCal] A            
		INNER JOIN NPA_IntegrationDetails B ON A.CustomerAcid=B.CustomerAcId
			 WHERE A.EffectiveFromTimeKey<=@TimeKey And A.EffectiveToTimeKey>=@TimeKey   

/*	insert data in AdvAcRestructureCal_hist table after upg praces*/
DELETE AdvAcRestructureCal_Hist WHERE EffectiveFromTimeKey=@TIMEKEY
INSERT INTO AdvAcRestructureCal_Hist
		(CustomerAcid
		,NCIF_ID
		,AssetClassAlt_KeyOnInvocation
		,PreRestructureAssetClassAlt_Key
		,PreRestructureNPA_Date
		,ProvPerOnRestrucure
		,RestructureTypeAlt_Key
		,COVID_OTR_CatgAlt_Key
		,RestructureDt
		,SP_ExpiryDate
		,DPD_AsOnRestructure
		,RestructureFailureDate
		,DPD_30_90_Breach_Date
		,ZeroDPD_Date
		,SP_ExpiryExtendedDate
		,CurrentPOS
		,CurrentTOS
		,RestructurePOS
		,Res_POS_to_CurrentPOS_Per
		,CurrentDPD
		,TotalDPD
		,VDPD
		,AddlProvPer
		,ProvReleasePer
		,AppliedNormalProvPer
		,FinalProvPer
		,PreDegProvPer
		,UpgradeDate
		,SurvPeriodEndDate
		,DegDurSP_PeriodProvPer
		,NonFinDPD
		,InitialAssetClassAlt_Key
		,FinalAssetClassAlt_Key
		,RestructureProvision
		,SecuredProvision
		,UnSecuredProvision
		,FlgDeg
		,FlgUpg
		,DegDate
		,RC_Pending
		,FinalNpaDt
		,RestructureStage
		,EffectiveFromTimeKey
		,EffectiveToTimeKey
		,AdditionalPOS
		,TEN_PC_DATE
		,SecondRestrDate
		,AggregateExposure
		,CreditRating1
		,CreditRating2
)
select CustomerAcid
		,NCIF_ID
		,AssetClassAlt_KeyOnInvocation
		,PreRestructureAssetClassAlt_Key
		,PreRestructureNPA_Date
		,ProvPerOnRestrucure
		,RestructureTypeAlt_Key
		,COVID_OTR_CatgAlt_Key
		,RestructureDt
		,SP_ExpiryDate
		,DPD_AsOnRestructure
		,RestructureFailureDate
		,DPD_30_90_Breach_Date
		,ZeroDPD_Date
		,SP_ExpiryExtendedDate
		,CurrentPOS
		,CurrentTOS
		,RestructurePOS
		,Res_POS_to_CurrentPOS_Per
		,CurrentDPD
		,TotalDPD
		,VDPD
		,AddlProvPer
		,ProvReleasePer
		,AppliedNormalProvPer
		,FinalProvPer
		,PreDegProvPer
		,UpgradeDate
		,SurvPeriodEndDate
		,DegDurSP_PeriodProvPer
		,NonFinDPD
		,InitialAssetClassAlt_Key
		,FinalAssetClassAlt_Key
		,RestructureProvision
		,SecuredProvision
		,UnSecuredProvision
		,FlgDeg
		,FlgUpg
		,DegDate
		,RC_Pending
		,FinalNpaDt
		,RestructureStage
		,@TimeKey EffectiveFromTimeKey
		,@TimeKey EffectiveToTimeKey
		,AdditionalPOS
		,TEN_PC_DATE
		,SecondRestrDate
		,AggregateExposure
		,CreditRating1
		,CreditRating2
	from AdvAcRestructureCal
/* END - 17062023 - for restructure deployment */


DROP TABLE #NCIF_ASSET
DROP TABLE #Temp
DROP TABLE #NPA_IntegrationDetails
DROP TABLE #AdvAcRestructureDetail

--UPDATE Audit Flag

--select count(1)  from  #NCIF_ASSET  ----   738732
end
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