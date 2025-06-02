SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE proc [dbo].[NPAINTEGRATION2]

@SourceName varchar(30),
@cost as float
AS

--Declare @SourceName varchar(30) = 'Finacle',
--@cost as float=1

select NCIF_Id,
CustomerId,
CustomerName,
PAN,
SourceName,
SrcSysAlt_Key,
AccountEntityID ,
isnull(SanctionedLimit,0)/@cost sanctionlimit
from NPA_IntegrationDetails NI

INNER JOIN DimSourceSystem DSS ON DSS.SourceAlt_Key = NI.SrcSysAlt_Key

where SourceName = @SourceName AND PAN = ' '
--and NCIF_Id='2179250'

GO