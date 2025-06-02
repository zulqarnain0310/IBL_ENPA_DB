SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

/*
Created By :- Vedika
Created Date:-26/09/2017
Report Name :- ENTCIF Missing in Source, Available in Dedup – Replace in Source
*/

CREATE  proc [dbo].[Rpt-ENTCIFMissingSource_AvailableDedup_A]
@DtEnter as varchar(20)
,@Cost as Float
,@ReportFilter As int
,@DimsourceSystem as int
AS

--DECLARE	
--@DtEnter as varchar(20)='30/09/2017'
--,@Cost AS FLOAT=1000
--,@ReportFilter As int=1
--,@DimsourceSystem as int=20

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1


DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
----Print @TimeKey 

--------------------------AVAILABLE IN DEDUP SYSTEM & MISSING IN SOURCE SYSTEM-------------

SELECT 


DimSourceSystem.SourceName										AS 'SourceSystem'

,Source_NCIF													AS 'SOURCEENTCIF'

,ChangedNCIF													AS 'CHANGEDENTCIF'

,NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'


,NPA_IntegrationDetails.PAN										AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,NPA_IntegrationDetails.CustomerACID							AS 'Account No.'

,NPA_IntegrationDetails.SanctionedLimit/@Cost					AS 'Limit'

,NPA_IntegrationDetails.Balance/@Cost							AS 'Outstanding'

,NCIF_ValFlag

,'Populated from Dedup System to Source System'					AS 'Action'

FROM (SELECT DISTINCT Client_ID,Source_NCIF,ChangedNCIF,NCIF_ValFlag,Timekey
	   FROM NCIF_VALIDATION
	   where NCIF_ValFlag='U'
	   )NCIF_VALIDATION

INNER JOIN NPA_IntegrationDetails		ON NPA_IntegrationDetails.CustomerId=NCIF_VALIDATION.Client_ID
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										--and #TEMP.PAN=NPA_IntegrationDetails.PAN
										and NPA_IntegrationDetails.EffectiveToTimeKey=NCIF_VALIDATION.Timekey

INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

WHERE @ReportFilter=1
AND (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)

--WHERE Client_ID='CU4687707'

--ORDER BY  NPA_IntegrationDetails.NCIF_Id	

UNION ALL

SELECT 


DimSourceSystem.SourceName										AS 'SourceSystem'

,Source_NCIF													AS 'SOURCEENTCIF'

,ChangedNCIF													AS 'CHANGEDENTCIF'

,NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'


,NPA_IntegrationDetails.PAN										AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,NPA_IntegrationDetails.CustomerACID							AS 'Account No.'

,NPA_IntegrationDetails.SanctionedLimit/@Cost					AS 'Limit'

,NPA_IntegrationDetails.Balance/@Cost							AS 'Outstanding'

,NCIF_ValFlag

,'Replaced from Dedup System in Source System'					AS 'Action'

FROM (SELECT DISTINCT Client_ID,NCIF_ValFlag,Source_NCIF, ChangedNCIF,Timekey
	   FROM NCIF_VALIDATION
	  where NCIF_ValFlag='D'
	   )NCIF_VALIDATION

INNER JOIN NPA_IntegrationDetails		ON NPA_IntegrationDetails.CustomerId=NCIF_VALIDATION.Client_ID
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										--and #TEMP.PAN=NPA_IntegrationDetails.PAN
										and NPA_IntegrationDetails.EffectiveToTimeKey=NCIF_VALIDATION.Timekey

INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey


WHERE @ReportFilter=2
AND ( DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)

UNION ALL

SELECT 


DimSourceSystem.SourceName										AS 'SourceSystem'


,Source_NCIF													AS 'SOURCEENTCIF'

,ChangedNCIF													AS 'CHANGEDENTCIF'


,NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'


,NPA_IntegrationDetails.PAN										AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,NPA_IntegrationDetails.CustomerACID							AS 'Account No.'

,NPA_IntegrationDetails.SanctionedLimit/@Cost					AS 'Limit'

,NPA_IntegrationDetails.Balance/@Cost							AS 'Outstanding'

,NCIF_ValFlag

,'To be alloted by Dedup System'											AS 'Action'

 FROM (SELECT DISTINCT Client_ID,NCIF_ValFlag,Timekey,Source_NCIF, ChangedNCIF
	   FROM NCIF_VALIDATION
	   where NCIF_ValFlag='C'  
	   )NCIF_VALIDATION

INNER JOIN NPA_IntegrationDetails		ON NPA_IntegrationDetails.CustomerId=NCIF_VALIDATION.Client_ID
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										--and #TEMP.PAN=NPA_IntegrationDetails.PAN
										and NPA_IntegrationDetails.EffectiveToTimeKey=NCIF_VALIDATION.Timekey

INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey


WHERE @ReportFilter=3
AND ( DimSourceSystem.SourceAlt_Key=@DimsourceSystem  OR @DimsourceSystem=0)

OPTION (RECOMPILE)


GO