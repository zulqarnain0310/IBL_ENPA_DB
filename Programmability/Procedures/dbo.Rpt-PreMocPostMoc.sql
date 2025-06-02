SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
--/*
--ALTERd By :- Baijayanti
--ALTERd Date:-29/09/2017
--Modified By :- Lakshmikanth
--Modified Date :- 03-11-2017
--Report Name :-Pre-Processing Manual Asset Class Change
--*/

CREATE  proc [dbo].[Rpt-PreMocPostMoc]
@DtEnter as varchar(20)
,@Cost as Float
AS

--DECLARE	
--@DtEnter as varchar(20)='30/09/2017'
--,@Cost AS FLOAT=1000

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1


DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
----Print @TimeKey 




IF OBJECT_ID('TEMPDB..#HistroyRecords')IS NOT NULL
DROP TABLE #HistroyRecords

 select NCIF_Id,AuthorisationStatus,ModifiedBy,DateModified
,Case when ISNULL(NCIF_AssetClassAlt_Key,'') <>''  Then NCIF_NPA_Date When  ISNULL(MOC_AssetClassAlt_Key,'') <>''  THEN MOC_NPA_Date END AS NCIF_NPA_Date
,Case when ISNULL(NCIF_AssetClassAlt_Key,'') <>''  Then NCIF_AssetClassAlt_Key When  ISNULL(MOC_AssetClassAlt_Key,'') <>'' THEN  MOC_AssetClassAlt_Key END AS  NCIF_AssetClassAlt_Key 
into #HistroyRecords from MOC_NPA_IntegrationDetails_MOD
where 
--EntityKey not in(


--select max(EntityKey)MinEntityKey from MOC_NPA_IntegrationDetails_MOD
--			where AuthorisationStatus IN ('A' ,'O')
			
--			-- and NCIF_Id='02777265E'
--group by NCIF_Id 

--) and 
AuthorisationStatus IN ('A' ,'O') -- and NCIF_Id='02777265E'


--SELECT * FROM #HistroyRecords

SELECT 
 @TimeKey                               AS TimeKey,
 @Cost                                   AS  Cost, 
 (MOCPO.NCIF_Id)						AS NCIF_ID

,MAX(A.CustomerName)				AS CUSTOMERNAME
			
,max(DimAssetClass.AssetClassName)   AS PreMOCAssetClass

,ISNULL(Convert(Varchar(20),MAX(MOCP.NCIF_NPA_Date),103),'NA')			AS PreMOCNPADate
	
,max(DimAssetClass1.AssetClassName)  AS  PostAssetClass

,ISNULL(Convert(Varchar(20),max(A.MOC_NPA_Date),103),'NA')				AS PostNPADate

,max(MOCPO.ModifiedBy)				AS PostModifiedBy

,max(MOCPO.DateModified)			AS PostModifiedDate	

,ISNULL(max(MOCPO.Remark),'NA')					AS PostRemark	

,(DimAssetClass2.AssetClassName)         AS HistoryAssetClass

,ISNULL(Convert(Varchar(20),(H.NCIF_NPA_Date),103),'NA')		AS HistoryNPADate

,MAX(A.ApprovedBy)                                   AS ApprovedBy
,MAX(A.DateApproved)                                 AS DateApproved
,ISNULL(MAX(A.MocAppRemark),'NA')                     AS AprovRemark
,ISNULL(h.ModifiedBy,'NA')						AS HistoryModifiedBy

,h.DateModified					               AS HistoryModifiedDate


 FROM 

NPA_IntegrationDetails A

INNER JOIN MOC_NPA_IntegrationDetails_MOD MOCP			 ON MOCP.NCIF_Id=A.NCIF_Id
														 AND MOCP.EffectiveFromTimeKey<=@TimeKey AND MOCP.EffectiveToTimeKey>=@TimeKey
														 AND A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey
														 AND MOCP.AuthorisationStatus in ('O')
														 --and a.NCIF_Id=#HistroyRecords.NCIF_Id

INNER JOIN MOC_NPA_IntegrationDetails_MOD MOCPO			ON MOCPO.NCIF_Id=A.NCIF_Id
														AND MOCPO.EffectiveFromTimeKey<=@TimeKey AND MOCPO.EffectiveToTimeKey>=@TimeKey
														AND MOCPO.AuthorisationStatus='A' 


LEFT JOIN DimAssetClass								ON DimAssetClass.AssetClassAlt_Key=MOCP.NCIF_AssetClassAlt_Key
														AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass		DimAssetClass1						ON DimAssetClass1.AssetClassAlt_Key=A.NCIF_AssetClassAlt_Key
														AND DimAssetClass1.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass1.EffectiveToTimeKey>=@TimeKey


LEFT JOIN  #HistroyRecords    H					 on (h.NCIF_Id=a.NCIF_Id)
													and h.NCIF_Id=MOCP.NCIF_Id
													and h.NCIF_Id=MOCPO.NCIF_Id
													and H.AuthorisationStatus in ('A','O')


LEFT JOIN DimAssetClass	DimAssetClass2							ON DimAssetClass2.AssetClassAlt_Key=H.NCIF_AssetClassAlt_Key
														AND DimAssetClass2.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass2.EffectiveToTimeKey>=@TimeKey

INNER JOIN SysDataMatrix								ON SysDataMatrix.TimeKey=@TimeKey
														AND SysDataMatrix.MOC_Freeze='Y'				-----ADDED AFTER DISCUSSING WITH RUPALI AND NISHANT ON (18/10/2017)..
														AND SysDataMatrix.MOC_FreezeBy IS NOT NULL
														AND SysDataMatrix.MOC_FreezeDate IS NOT NULL
										
--WHERE 
--------A.AuthorisationStatus='A' and
-- a.NCIF_Id='02777265E'

group by 
----DimAssetClass.AssetClassName,DimAssetClass1.AssetClassName, 

(h.ModifiedBy)	--,MOCPO.Remark				

,(h.DateModified)
,(MOCPO.NCIF_Id),	
(H.NCIF_NPA_Date)		
,DimAssetClass2.AssetClassName 
,H.NCIF_AssetClassAlt_Key 

ORDER BY H.NCIF_AssetClassAlt_Key 
Option (Recompile)
DROP TABLE #HistroyRecords


--SELECT * FROM SysDataMatrix WHERE MOC_Freeze='y'



GO