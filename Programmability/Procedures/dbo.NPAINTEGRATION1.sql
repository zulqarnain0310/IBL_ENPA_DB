SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
Create proc [dbo].[NPAINTEGRATION1]
AS


select NCIF_Id,
CustomerId,
CustomerName,
PAN,
SourceName,
SrcSysAlt_Key,
AccountEntityID 
from NPA_IntegrationDetails NI


INNER JOIN DimSourceSystem DSS ON DSS.SourceAlt_Key = NI.SrcSysAlt_Key

where SourceName = 'Finacle' AND PAN = ' '


Exec NPAINTEGRATION1
GO