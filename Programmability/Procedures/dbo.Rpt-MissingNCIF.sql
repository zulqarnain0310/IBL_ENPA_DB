SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
/*
---ALTERd By :- Vedika 
---ALTERd Date :- 02/10/2017
----Report Name :- Missing NCIF
--
*/

CREATE  proc [dbo].[Rpt-MissingNCIF]
@DtEnter as varchar(20)
,@Cost AS FLOAT
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


DimSourceSystem.SourceName										AS 'SourceSystem'


,NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'


,NPA_IntegrationDetails.PAN										AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,NPA_IntegrationDetails.CustomerACID							AS 'Account No.'

,NPA_IntegrationDetails.SanctionedLimit/@Cost					AS 'Limit'

,NPA_IntegrationDetails.Balance/@Cost							AS 'Outstanding'

,NCIF_ValFlag

FROM (SELECT DISTINCT Client_ID,NCIF_ValFlag,Timekey
	   FROM NCIF_VALIDATION
	  where NCIF_ValFlag='C'  OR NCIF_ValFlag='U'
	   )NCIF_VALIDATION

INNER JOIN NPA_IntegrationDetails		ON NPA_IntegrationDetails.CustomerId=NCIF_VALIDATION.Client_ID
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										--and #TEMP.PAN=NPA_IntegrationDetails.PAN
										and NPA_IntegrationDetails.EffectiveToTimeKey=NCIF_VALIDATION.Timekey

INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey





option(recompile)


GO