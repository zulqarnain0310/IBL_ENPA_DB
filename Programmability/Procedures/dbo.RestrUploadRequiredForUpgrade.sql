SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
--USE [IBL_ENPA_DB_LOCAL_DEV]
--GO
--/****** Object:  StoredProcedure [dbo].[RestrUploadRequiredForUpgrade]    Script Date: 17-05-2023 15:04:07 ******/
--SET ANSI_NULLS ON--GO
--SET QUOTED_IDENTIFIER ON--GO



CREATE   PROC [dbo].[RestrUploadRequiredForUpgrade] 
WITH RECOMPILE
AS 

DECLARE @TimeKey int
SELECT @TimeKey=MAX(EFFECTIVEFROMTIMEKEY) FROM AdvAcRestructureCal


DECLARE @OverdueRefDPD INT=(SELECT RefValue FROM RefPeriod WHERE EffectiveFromTimeKey<=@TImeKey AND EffectiveToTimeKey>=@TimeKey AND BusinessRule='Refperiodoverdueupg')
		,@ContiExcessREdDPD INT=(SELECT RefValue FROM RefPeriod WHERE EffectiveFromTimeKey<=@TImeKey AND EffectiveToTimeKey>=@TimeKey AND BusinessRule='Refperiodoverdrawnupg')
		,@IntNotServiceRefDPD INT=(SELECT RefValue FROM RefPeriod WHERE EffectiveFromTimeKey<=@TImeKey AND EffectiveToTimeKey>=@TimeKey AND BusinessRule='Refperiodintserviceupg')
		,@StkStamentRedDPD INT=(SELECT RefValue FROM RefPeriod WHERE EffectiveFromTimeKey<=@TImeKey AND EffectiveToTimeKey>=@TimeKey AND BusinessRule='Refperiodstkstatementupg')
		,@RenewalDueRefDPD INT=(SELECT RefValue FROM RefPeriod WHERE EffectiveFromTimeKey<=@TImeKey AND EffectiveToTimeKey>=@TimeKey AND BusinessRule='Refperiodreviewupg')
		,@Processingdate DATE=(SELECT DATE FROM SysDataMatrix WHERE TimeKey=@TIMEKEY)

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


	DROP TABLE IF EXISTS #NPA_IntegrationDetails
	SELECT  NCIF_Id
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
			,MaxDPD
			/*----FOR REPORT  */
			,UNSERVED_INTEREST
			,IntOverdue
			,PrincipleOutstanding
			,CustomerName
			,SrcSysAlt_Key
			,Balance
		INTO #NPA_IntegrationDetails FROM NPA_IntegrationDetails
	WHERE EffectiveFromTimeKey<=@TIMEKEY  and EffectiveToTimeKey>=@TIMEKEY

	CREATE NONCLUSTERED INDEX idx_NPA_IntegrationDetail_temp ON #NPA_IntegrationDetails(CustomerACID)

	DROP TABLE IF EXISTS #AdvAcRestructureDetail
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

  SELECT NPA.NCIF_Id,npa.CustomerACID, ParameterShortNameEnum RestructureType 
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
							and (ISNULL(NPA.IsRestructured,'N')='Y' ) 
							AND ISNULL(ParameterShortNameEnum,'') IN( /*Covid-19 Other than Personal Loan */
																						'Corporate-Aug20-Extn-May21','Corporate-Aug20'
																						/*Covid-19 OTR Personal Loan, Business Loand and Individual Business */
																						/* Under Irac/Normal Restrucuture Under Irac */
																						,'Others','Others_Jun19'
																	)

								AND ISNULL(NPA.MaxDPD,0)=0 and TEN_PC_DATE IS NOT NULL
								AND ISNULL(RES.SP_ExpiryExtendedDate,RES.SP_ExpiryDate)<@Processingdate
								--AND SecondRestrDate IS Not Null

															  
 CREATE NONCLUSTERED INDEX idx_Restructured_NCIF_Id ON #Restructured_NCIF_Id(NCIF_Id)

IF OBJECT_ID('TEMPDB..#NCIF_ASSET') IS NOT NULL
DROP TABLE #NCIF_ASSET

SELECT DISTINCT	 A.NCIF_Id
			,CustomerId
			,CustomerACID
			,NCIF_AssetClassAlt_Key
			,DPD_Overdue_Loans
			,DPD_Overdrawn
			,IsCentral_GovGty
			,GtyRepudiated
			,DPD_Interest_Not_Serviced
			,DPD_StockStmt
			,DPD_Renewals
			,CAST('N' AS VARCHAR(1)) FlgUpg
			,UNSERVED_INTEREST
			,IntOverdue
			,PrincipleOutstanding
			,CustomerName
			,SrcSysAlt_Key
			,Balance
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
					  OR (AC_AssetClassAlt_Key=@LOS_Alt_Key AND ISNULL(IsFraud,'Y')='Y'))
                          AND NID.NCIF_Id=A.NCIF_Id)
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
  
  drop table if exists Restructure_Upgrade_Output 
  
	SELECT a.NCIF_Id NCIF ,a.CustomerId CIF,a.CustomerACID Account_Number ,src.SourceName Source_System,CustomerName Name
					,B.RestructureType Type_of_Restructuring,PrincipleOutstanding POS,
					IntOverdue Int_Overdue,
					Balance,CONVERT(nvarchar, @Processingdate ,103) Upgrade_Elligibility_Date
			into Restructure_Upgrade_Output FROM #NCIF_ASSET a
		INNER JOIN #Restructured_NCIF_Id B
			ON A.CustomerACID=B.CustomerACID
		inner join DimSourceSystem src
			on src.EffectiveFromTimeKey<=@TimeKey and src.EffectiveToTimeKey>=@TimeKey
			and src.SourceAlt_Key=a.SrcSysAlt_Key
	WHERE ISNULL(RestructureType,'') IN( /*Covid-19 Other than Personal Loan */
												'Corporate-Aug20-Extn-May21','Corporate-Aug20'
												/*Covid-19 OTR Personal Loan, Business Loand and Individual Business */
												,'PL-Aug20','Ind.Business-May21','SmallBusiness-May21','PL-May21','Ind.Business-Aug20-May21','SmallBusiness-Aug20-May21','PL-Aug20-May21'
												/* Under Irac/Normal Restrucuture Under Irac */
												,'Others','Others_Jun19'
											)
								AND
								 ISNULL(DPD_Overdue_Loans,0)<=@OverdueRefDPD
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
								  and NCIF_AssetClassAlt_Key>1
GO