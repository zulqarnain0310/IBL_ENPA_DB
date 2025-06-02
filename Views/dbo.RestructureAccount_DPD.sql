SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE VIEW
[dbo].[RestructureAccount_DPD]
AS

SELECT A.*,B.DATE DPD_DATE FROM(
	  SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_may2023_new
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Mar2023
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Jan2023new
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Feb2023
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Apr2023_new
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Sep2022
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Oct2022
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Nov2022
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_May2022
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Mar2022
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Jun2022
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Jul2022
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Jan2022
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Feb2022
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Dec2022
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Aug2022
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Apr2022
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Sep2021
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_OCT2021
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Nov2021
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_Dec2021
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_August2021
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_july2021
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_missing_record
UNION SELECT NCIF_Id, CustomerId, AccountEntityID, CustomerACID, MaxDPD, TimeKey FROM RestructureAccount_DPD_New
)A
INNER JOIN SysDaymatrix B
	ON A.TIMEKEY=B.TimeKey




--SELECT timekey FROM RestructureAccount_DPD
--group by timekey
--order by timekey
GO