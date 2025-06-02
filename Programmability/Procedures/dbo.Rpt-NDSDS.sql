SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
/*
ALTERd By :- Baijayanti
ALTERd Date:-29/09/2017
Report Name :-NCIF Duplication in Source and Dedup system

*/

CREATE  proc[dbo].[Rpt-NDSDS]
@DtEnter as varchar(20)
AS

--DECLARE	
--@DtEnter as varchar(20)='31/08/2017'

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1


DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
----Print @TimeKey 


SELECT 


DimSourceSystem.SourceName										   AS 'SourceSystem'

,NCIF															   AS 'NCIF'

,DedupSysData.SrcAppCustomerID									   AS 'CustomerID'

,NPA_IntegrationDetails.CustomerName							   AS 'CustomerName'

,DedupSysData.PAN                                                  AS 'PAN'

,NPA_IntegrationDetails.ProductType								   AS 'Facility'

,NPA_IntegrationDetails.AccountEntityID							   AS 'Account No.'

,NPA_IntegrationDetails.SanctionedLimit							   AS 'Limit'

,NPA_IntegrationDetails.Balance									   AS 'Outstanding'

			
FROM DedupSysData

INNER JOIN NPA_IntegrationDetails		ON NPA_IntegrationDetails.NCIF_Id=DedupSysData.NCIF
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey 
										AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey

INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=DedupSysData.SrcAppAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

OPTION(RECOMPILE)



GO