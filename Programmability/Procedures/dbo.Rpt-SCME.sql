SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

--/*
--Created By :- Vedika
--Created Date:-26/09/2017
--Report Name :-Single Client ID in Source system with Multiple ENTCIF
--*/


CREATE  proc [dbo].[Rpt-SCME]
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


--select COUNT( distinct NCIF_Id)NCIF_Id,CustomerId
--from NPA_IntegrationDetails 
--group by CustomerID 
--having COUNT(distinct NCIF_Id)>1
--)temp

select 

DimSourceSystem.SourceName										AS 'SourceSystem'

,ClientID_NCIF_MismatchDetails.NCIF								AS 'NCIF'

,ClientID_NCIF_MismatchDetails.CustomerID						AS 'CustomerID'

,ClientID_NCIF_MismatchDetails.CustomerName						AS 'CustomerName'

,ClientID_NCIF_MismatchDetails.PAN								AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,NPA_IntegrationDetails.CustomerACID							AS 'Account No.'

,NPA_IntegrationDetails.SanctionedLimit/@Cost					AS 'Limit'

,NPA_IntegrationDetails.Balance/@Cost							AS 'Outstanding'

 from  ClientID_NCIF_MismatchDetails

 INNER JOIN NPA_IntegrationDetails				ON NPA_IntegrationDetails.CustomerId=ClientID_NCIF_MismatchDetails.CustomerID
												AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
												AND ClientID_NCIF_MismatchDetails.TimeKey=NPA_IntegrationDetails.EffectiveToTimeKey

INNER JOIN DimSourceSystem						ON  DimSourceSystem.SourceAlt_Key=ClientID_NCIF_MismatchDetails.SrcSysAlt_Key
												AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
										

OPTION (RECOMPILE)


GO