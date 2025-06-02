SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
/*
ALTERd By :- Vedika
ALTERd Date:-03/10/2017
Report Name :- CASA
*/

CREATE Proc [dbo].[Rpt-CASA_SUB]

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


SELECT 

DISTINCT

CASA_NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'

------------------------------------CASA SYSTEM-----------------------------------------

,DimSourceSystem2.SourceName										AS 'CASA_SourceSystem'

,CASA_NPA_IntegrationDetails.CustomerId								AS 'CASA_CustomerID'

,CASA_NPA_IntegrationDetails.CustomerName							AS 'CASA_CustomerName'

,CASA_NPA_IntegrationDetails.CustomerACID							AS 'CASA_ACID'

,CASA_NPA_IntegrationDetails.ProductType							AS 'CASA_Facility'

,CASA_NPA_IntegrationDetails.SanctionedLimit/@Cost					AS 'CASA_Limit'

,CASA_DimAssetClass.AssetClassName									AS 'CASA_AssetClass'

,CASA_NPA_IntegrationDetails.Balance/@Cost							AS 'CASA_Outstanding'


FROM NPA_IntegrationDetails

 INNER JOIN  CASA_NPA_IntegrationDetails				ON CASA_NPA_IntegrationDetails.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
														AND CASA_NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND CASA_NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
														AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey

INNER JOIN DimAssetClass  CASA_DimAssetClass			ON CASA_DimAssetClass.AssetClassAlt_Key=CASA_NPA_IntegrationDetails.AC_AssetClassAlt_Key
														AND CASA_DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND CASA_DimAssetClass.EffectiveToTimeKey>=@TimeKey

INNER JOIN DimSourceSystem	DimSourceSystem2			ON  DimSourceSystem2.SourceAlt_Key=CASA_NPA_IntegrationDetails.SrcSysAlt_Key
														AND DimSourceSystem2.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem2.EffectiveToTimeKey>=@TimeKey


WHERE NPA_IntegrationDetails.AC_AssetClassAlt_Key<>1
and CASA_NPA_IntegrationDetails.NCIF_Id='10030829'
--and CASA_NPA_IntegrationDetails.NCIF_Id=@NCIF_Id

ORDER BY CASA_NPA_IntegrationDetails.NCIF_Id--,CASA_NPA_IntegrationDetails.CustomerACID
option (recompile)
GO