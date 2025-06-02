SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

/*
ALTERd By :- Vedika
ALTERd Date:-29/11/2017
Report Name :- Lowest Asset Classification Percolation Report-Post MOC(ONLY MOC RECORDS)
*/


CREATE PROC [dbo].[Rpt-LowestAssetPerculation_PostMOC_ONLYMOC]
@DtEnter as varchar(20)
AS

--DECLARE	
--@DtEnter as varchar(20)='31/03/2018'

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1

DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
Print @TimeKey 

SELECT * INTO #TEMP FROM
(
select DISTINCT  
		NPA_IntegrationDetails.NCIF_Id,
		DimSourceSystem.SourceName,
		--NPA_IntegrationDetails.CustomerId,
		--NPA_IntegrationDetails.CustomerName,
		DimAssetClass.AssetClassShortNameEnum  NCIF_AssetClassAlt_Key,
		convert(varchar(25),NPA_IntegrationDetails.NCIF_NPA_Date,103)NCIF_NPA_Date,
		MOC_NPA_IntegrationDetails_MOD.ModifiedBy,
		MOC_NPA_IntegrationDetails_MOD.DateModified,
		MOC_NPA_IntegrationDetails_MOD.MOC_Remark,
		MOC_NPA_IntegrationDetails_MOD.ApprovedBy,
		MOC_NPA_IntegrationDetails_MOD.DateApproved,
		MOC_NPA_IntegrationDetails_MOD.MocAppRemark 
		--ROW_NUMBER() OVER(PARTITION BY NCIF_ID ORDER BY NCIF_ID)SR_NO
		from NPA_IntegrationDetails
		inner join MOC_NPA_IntegrationDetails_MOD				ON MOC_NPA_IntegrationDetails_MOD.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
																AND MOC_NPA_IntegrationDetails_MOD.AuthorisationStatus='O'
																AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
																AND MOC_NPA_IntegrationDetails_MOD.EffectiveFromTimeKey<=@TimeKey  AND MOC_NPA_IntegrationDetails_MOD.EffectiveToTimeKey>=@TimeKey
																--AND  MOC_NPA_IntegrationDetails_MOD.NCIF_Id='10030829'

		
		INNER JOIN DimSourceSystem  							ON DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
																AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey and DimSourceSystem.EffectiveToTimeKey>=@TimeKey

		INNER JOIN DimAssetClass									ON DimAssetClass.AssetClassAlt_Key=MOC_NPA_IntegrationDetails_MOD.NCIF_AssetClassAlt_Key
																	AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey
		
		INNER JOIN	SysDataMatrix								ON SysDataMatrix.TimeKey=@TimeKey
																and MOC_Freeze='Y'
																AND MOC_FreezeBy IS NOT NULL
																AND MOC_FreezeDate IS NOT NULL

union all
select DISTINCT MOC_NPA_IntegrationDetails_MOD.NCIF_Id,
				DimSourceSystem.SourceName,
				--NPA_IntegrationDetails.CustomerId,
				--NPA_IntegrationDetails.CustomerName,
				DimAssetClass.AssetClassShortNameEnum MOC_AssetClassAlt_Key,
				convert(varchar(25),MOC_NPA_IntegrationDetails_MOD.MOC_NPA_Date,103)MOC_NPA_Date,
				MOC_NPA_IntegrationDetails_MOD.ModifiedBy,
				MOC_NPA_IntegrationDetails_MOD.DateModified,
				MOC_NPA_IntegrationDetails_MOD.MOC_Remark,
				MOC_NPA_IntegrationDetails_MOD.ApprovedBy,
				MOC_NPA_IntegrationDetails_MOD.DateApproved,
				MOC_NPA_IntegrationDetails_MOD.MocAppRemark 
			
				from MOC_NPA_IntegrationDetails_MOD
				inner join NPA_IntegrationDetails				ON MOC_NPA_IntegrationDetails_MOD.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
																AND MOC_NPA_IntegrationDetails_MOD.AuthorisationStatus<>'O'
																AND MOC_NPA_IntegrationDetails_MOD.AuthorisationStatus='A'
																AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
																AND MOC_NPA_IntegrationDetails_MOD.EffectiveFromTimeKey<=@TimeKey  AND MOC_NPA_IntegrationDetails_MOD.EffectiveToTimeKey>=@TimeKey


				INNER JOIN DimSourceSystem  					ON DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
																and DimSourceSystem.EffectiveFromTimeKey<=@TimeKey and DimSourceSystem.EffectiveToTimeKey>=@TimeKey

				INNER JOIN DimAssetClass						ON DimAssetClass.AssetClassAlt_Key=MOC_NPA_IntegrationDetails_MOD.MOC_AssetClassAlt_Key
																AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey
				
				INNER JOIN	SysDataMatrix						ON SysDataMatrix.TimeKey=@TimeKey
																and MOC_Freeze='Y'
																AND MOC_FreezeBy IS NOT NULL
																AND MOC_FreezeDate IS NOT NULL
)TEMP

OPTION(RECOMPILE)

SELECT 
NCIF_Id,
SourceName,
--CustomerId,
--CustomerName,
NCIF_AssetClassAlt_Key,
LEAD(NCIF_AssetClassAlt_Key) OVER(ORDER BY NCIF_ID,dateapproved)NEWNCIFASSET,
NCIF_NPA_Date,
LEAD(NCIF_NPA_Date) OVER(ORDER BY NCIF_ID,dateapproved)NEWNPA_DATE,
ModifiedBy,
LEAD(ModifiedBy) OVER(ORDER BY NCIF_ID,dateapproved)NEWModifiedBy,
DateModified,
LEAD(DateModified) OVER(ORDER BY NCIF_ID,dateapproved)NEWDateModified,
MOC_Remark,
LEAD(MOC_Remark) OVER(ORDER BY NCIF_ID,dateapproved)NEWMOC_Remark,
ApprovedBy,
LEAD(ApprovedBy) OVER(ORDER BY NCIF_ID,dateapproved)NEWApprovedBy,
DateApproved,
LEAD(DateApproved) OVER(ORDER BY NCIF_ID,dateapproved)NEWDateApproved,
MocAppRemark,
LEAD(MocAppRemark) OVER(ORDER BY NCIF_ID,dateapproved)NEWMocAppRemark,
ROW_NUMBER() OVER(PARTITION BY NCIF_ID ORDER BY NCIF_ID)SR_NO
INTO #TEMP1
 FROM #TEMP

OPTION(RECOMPILE)

SELECT MAX(SR_NO)MAXSR_NO,NCIF_Id INTO #TEMP2 FROM #TEMP1 GROUP BY NCIF_Id
order by NCIF_Id

OPTION(RECOMPILE)

UPDATE #TEMP1
SET NEWNCIFASSET=NULL,
NEWNPA_DATE=NULL,
NEWApprovedBy=NULL,
NEWDateApproved=NULL,
NEWMocAppRemark=NULL,
NEWDateModified=NULL,
NEWModifiedBy=NULL,
NEWMOC_Remark=NULL

FROM #TEMP1			INNER JOIN #TEMP2		ON #TEMP1.NCIF_Id=#TEMP2.NCIF_Id
											AND #TEMP1.SR_NO=#TEMP2.MAXSR_NO

OPTION(RECOMPILE)

SELECT 
distinct 
NCIF_Id,
SOURCENAME,
NCIF_AssetClassAlt_Key  AS PreviousAssetClass,
NCIF_NPA_Date		   AS PreviousNPADate,
ModifiedBy			   AS PreviousModifyBy,
DateModified		  AS PreviousDateModified,
MOC_Remark			   AS PreviousMOCRemark,
ApprovedBy			   AS PreviousApprovedBY,
DateApproved			AS PreviousDateApproved,
MocAppRemark			AS PreviousMOCApproveRemark,
NEWNCIFASSET			AS FinalAssetClass,
NEWNPA_DATE			   AS FinalNPADate,
NEWModifiedBy		   AS FinalModifyBY,
NEWDateModified		   AS FinalDateModified,
NEWMOC_Remark		   AS FinalMOCRemark,
NEWApprovedBy		 AS FinalApprovedBY,
NEWDateApproved		   AS FinalDateApproved,
NEWMocAppRemark		   AS FinalMOCApprovedRemark,
SR_NO
	
FROM #TEMP1

WHERE NEWNCIFASSET is not null

order by NCIF_Id,DateApproved

OPTION(RECOMPILE)

DROP TABLE #TEMP,#TEMP1,#TEMP2


GO