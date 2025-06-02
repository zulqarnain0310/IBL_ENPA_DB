SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
--------/*
--------ALTERd By :- Baijayanti
--------ALTERd Date:-29/09/2017
--------Modified By :- Vedika
--------Modified Date :- 02-10-2017
--------Report Name :-Pre-Processing Manual Asset Class Change
--------*/

CREATE  proc [dbo].[Rpt-PPMACC]
@DtEnter as varchar(20)
,@Cost as Float
,@DimsourceSystem as int
AS

--DECLARE	
--@DtEnter as varchar(20)='31/12/2017'
--,@Cost AS FLOAT=1000
--,@DimsourceSystem as int=0

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1


DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
----Print @TimeKey 

-----select * from (

SELECT 
DISTINCT

DimSourceSystem.SourceName										   AS 'SourceSystem'


,NPA_IntegrationDetails.NCIF_Id									   AS 'NCIF'


,NPA_IntegrationDetails.CustomerId								   AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							   AS 'CustomerName'

,NPA_IntegrationDetails.ProductType								   AS 'Facility'

,case when len(NPA_IntegrationDetails.CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end													 AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost				AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost					    AS 'Outstanding'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost				AS 'DrawingPower'

,ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost AS 'POS'

,NPA_IntegrationDetails.SubSegment							        AS 'SubSegment'


,isnull(NPA_IntegrationDetails.DPD_Renewals,0)                      AS 'DPD_Renewals'

---------------------System Classified------------------------
,NPA_IntegrationDetails.MaxDPD                                        AS 'SYS_DPD'
,DimAssetClass.AssetClassName                                     AS 'SYS_Asset Class'
,CONVERT(VARCHAR(20),NPA_IntegrationDetails_MOD.AC_NPA_Date,103)   AS 'SYS_NPADate'

-----------------Modified--------------
,NPA_IntegrationDetails.MaxDPD                                        AS 'MOD_DPD'
--,DimAssetClass.AssetClassName                                      AS 'MOD_Asset Class'
--,CONVERT(VARCHAR(20),NPA_IntegrationDetails.AC_NPA_Date,103)	   AS 'MOD_NPADate'

,ISNULL(MOCASSET.AssetClassName,DimAssetClass.AssetClassName)				AS 'MOD_Asset Class'

,CONVERT(VARCHAR(20),NPA_IntegrationDetails.AC_NPA_Date,103)	AS 'MOD_NPADate'

,NPA_IntegrationDetails.ModifiedBy								   AS 'ModifiedBy'
,CONVERT(VARCHAR(20),NPA_IntegrationDetails.DateModified,103)	   AS 'ModifiedDate' 
,NPA_IntegrationDetails.AstClsChngRemark						   AS 'ModifierRemarks'	
,NPA_IntegrationDetails.ApprovedBy								   AS 'AuthoriserID'	
,CONVERT(VARCHAR(20),NPA_IntegrationDetails.DateApproved,103)	   AS 'AuthoriserDate'	
,NPA_IntegrationDetails.AstClsAppRemark							   AS 'AuthoriserRemarks'
			
                
FROM NPA_IntegrationDetails

INNER JOIN NPA_IntegrationDetails_MOD		ON NPA_IntegrationDetails.NCIF_Id=NPA_IntegrationDetails_MOD.NCIF_Id
											AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
											AND NPA_IntegrationDetails.AuthorisationStatus='A'
											AND NPA_IntegrationDetails.CustomerACID=NPA_IntegrationDetails_MOD.CustomerACID

INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass				    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails_MOD.AC_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	

--INNER JOIN DimAssetClass					ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
--										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

--INNER JOIN DimAssetClass	         DimAssetClass1	ON DimAssetClass1.AssetClassAlt_Key=NPA_IntegrationDetails_MOD.AC_AssetClassAlt_Key
--										AND DimAssetClass1.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass1.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

INNER JOIN SysDataMatrix				 ON SysDataMatrix.TimeKey=@TimeKey

WHERE NPA_IntegrationDetails.DateModified is not null --AND NPA_IntegrationDetails.CustomerId='10643024'
	  AND NPA_IntegrationDetails.ModifiedBy is not null 
	  AND NPA_IntegrationDetails.ApprovedBy IS NOT NULL
	  AND NPA_IntegrationDetails.AstClsChngDate IS NOT NULL
	  AND NPA_IntegrationDetails_MOD.AuthorisationStatus='O'
	  AND ( DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)
	  
	--------------------Added after Discussion with Shishir sir---------------  
	  AND PreProcessingFreeze='Y'						
	  AND PreProcessingFreezeBy IS NOT NULL
	  AND PreProcessingFreezeDate IS NOT NULL
	  
---- )A WHERE  @NPA=0


--union all

--select * from (

--SELECT 


--DimSourceSystem.SourceName										   AS 'SourceSystem'


--,NPA_IntegrationDetails.NCIF_Id									   AS 'NCIF'


--,NPA_IntegrationDetails.CustomerId								   AS 'CustomerID'


--,NPA_IntegrationDetails.CustomerName							   AS 'CustomerName'

--,NPA_IntegrationDetails.ProductType								   AS 'Facility'

--,NPA_IntegrationDetails.CustomerACID							   AS 'Account No.'

--,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			   AS 'Limit'

--,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost					   AS 'Outstanding'

--,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost						 AS 'DrawingPower'

--,NPA_IntegrationDetails.SubSegment							       AS 'SubSegment'

--,NPA_IntegrationDetails.DPD_Renewals                               AS 'DPD_Renewals'


-----------------------System Classified------------------------
--,NPA_IntegrationDetails.MaxDPD                                     AS 'SYS_DPD'
--,DimAssetClass.AssetClassName                                      AS 'SYS_Asset Class'
--,CONVERT(VARCHAR(20),NPA_IntegrationDetails_MOD.AC_NPA_Date,103)   AS 'SYS_NPADate'

-------------------Modified--------------
--,NPA_IntegrationDetails.MaxDPD                                        AS 'MOD_DPD'
----,DimAssetClass.AssetClassName                                      AS 'MOD_Asset Class'
----,CONVERT(VARCHAR(20),NPA_IntegrationDetails.AC_NPA_Date,103)	   AS 'MOD_NPADate'

--,ISNULL(MOCASSET.AssetClassName,DimAssetClass.AssetClassName)				AS 'MOD_Asset Class'

--,ISNULL(CAST(NPA_IntegrationDetails.NCIF_NPA_Date AS varchar(25)),'NA')		AS 'MOD_NPADate'

--,NPA_IntegrationDetails.ModifiedBy								   AS 'ModifiedBy'
--,CONVERT(VARCHAR(20),NPA_IntegrationDetails.DateModified,103)	   AS 'ModifiedDate' 
--,NPA_IntegrationDetails.AstClsChngRemark						   AS 'ModifierRemarks'	
--,NPA_IntegrationDetails.ApprovedBy								   AS 'AuthoriserID'	
--,CONVERT(VARCHAR(20),NPA_IntegrationDetails.DateApproved,103)	   AS 'AuthoriserDate'	
--,NPA_IntegrationDetails.AstClsAppRemark							   AS 'AuthoriserRemarks'
			
                
--FROM NPA_IntegrationDetails

--INNER JOIN NPA_IntegrationDetails_MOD		ON NPA_IntegrationDetails.NCIF_Id=NPA_IntegrationDetails_MOD.NCIF_Id
--											AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
--											AND NPA_IntegrationDetails.AuthorisationStatus='A'
--											AND NPA_IntegrationDetails.CustomerACID=NPA_IntegrationDetails_MOD.CustomerACID

--INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
--										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

--LEFT JOIN DimAssetClass				    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails_MOD.AC_AssetClassAlt_Key
--										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

--LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
--										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	

--INNER JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
--										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey


----INNER JOIN DimAssetClass				ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
----										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

----INNER JOIN DimAssetClass	            DimAssetClass1	ON DimAssetClass1.AssetClassAlt_Key=NPA_IntegrationDetails_MOD.AC_AssetClassAlt_Key
----										AND DimAssetClass1.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass1.EffectiveToTimeKey>=@TimeKey

--INNER JOIN SysDataMatrix				 ON SysDataMatrix.TimeKey=@TimeKey

--WHERE NPA_IntegrationDetails.DateModified is not null 
--	  AND NPA_IntegrationDetails.ModifiedBy is not null 
--	  AND NPA_IntegrationDetails.ApprovedBy IS NOT NULL
--	  AND NPA_IntegrationDetails.AstClsChngDate IS NOT NULL
--	  AND NPA_IntegrationDetails_MOD.AuthorisationStatus='O'
--	  AND ( DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)
	  
--	--------------------Added after Discussion with Shishir sir---------------  
--	  --AND PreProcessingFreeze='Y'						
--	  --AND PreProcessingFreezeBy IS NOT NULL
--	  --AND PreProcessingFreezeDate IS NOT NULL
	  
--	  AND (NPA_IntegrationDetails.AC_AssetClassAlt_Key<>7
--AND (ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)<>1
--	  OR  (ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)=1
     
--	      AND 

--           CASE WHEN  AgriFlag='N' THEN  (  CASE WHEN isnull(MaxDPD,0)>isnull(DPD_Renewals,0) THEN  (CASE WHEN isnull(MaxDPD,0)>90 THEN 1 END)
--								          WHEN isnull(DPD_Renewals,0)>isnull(MaxDPD,0) THEN (CASE WHEN DPD_Renewals>180 THEN 1 END)
--									END )
									
--                WHEN AgriFlag='Y' THEN  (  CASE WHEN isnull(MaxDPD,0)>isnull(DPD_Renewals,0) THEN  (CASE WHEN isnull(MaxDPD,0)>365 THEN 1 END)
--								          WHEN isnull(DPD_Renewals,0)>isnull(MaxDPD,0) THEN (CASE WHEN DPD_Renewals>180 THEN 1 END)
--									END )							
											
--										END =1 
--		)
--     )
--     )
	  
--	   )A  WHERE  @NPA=1




option(recompile)







GO