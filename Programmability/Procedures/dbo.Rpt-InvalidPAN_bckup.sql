SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

--/*
--Created By :- Vedika
--Created Date:-26/09/2017
--Report Name :-Invalid PAN 

--*/

CREATE Proc [dbo].[Rpt-InvalidPAN_bckup]
@DtEnter as varchar(20)
,@Cost AS FLOAT
,@DimsourceSystem as int
AS

--DECLARE	

--@DtEnter as varchar(20)='30/09/2017'
--,@Cost AS FLOAT=1000
--,@DimsourceSystem as int=0

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1


DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
----Print @TimeKey 


SELECT 


DimSourceSystem.SourceName													AS 'SourceSystem'


,NPA_IntegrationDetails.NCIF_Id												AS 'NCIF'


,NPA_IntegrationDetails.CustomerID											AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName										AS 'CustomerName'


,NPA_IntegrationDetails.PAN													AS 'PAN'

,NPA_IntegrationDetails.ProductType											AS 'Facility'

,NPA_IntegrationDetails.CustomerACID										AS 'Account No.'

,NPA_IntegrationDetails.SanctionedLimit/@Cost								AS 'Limit'

,NPA_IntegrationDetails.Balance/@Cost										AS 'Outstanding'


,DimAssetClass.AssetClassName												AS 'ASSETCLASS'

,ISNULL(CAST(NPA_IntegrationDetails.NCIF_NPA_Date AS varchar(25)),'NA')		AS 'NPADATE'


FROM NPA_IntegrationDetails


INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
								

INNER JOIN DimAssetClass				ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey


WHERE 

(DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)

AND 

((len(PAN)=10 AND (left(PAN,5 ) NOT like'%[A-Z]%' OR substring(PAN,6,4) NOT  like'%[0-9]%'OR  right(PAN,1)NOT  like'%[A-Z]%' )))

and ( PAN NOT LIKE 'form%'  AND Pan Not like 'from%' )-------------------------as per discussion with shishir sir --26/10/2017                           

ORDER BY NPA_IntegrationDetails.NCIF_Id

option(recompile)
GO