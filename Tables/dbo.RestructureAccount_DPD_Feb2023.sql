CREATE TABLE [dbo].[RestructureAccount_DPD_Feb2023] (
  [NCIF_Id] [varchar](15) NULL,
  [CustomerId] [varchar](20) NULL,
  [AccountEntityID] [int] NULL,
  [CustomerACID] [varchar](20) NULL,
  [MaxDPD] [int] NULL,
  [TimeKey] [int] NULL,
  CHECK ([TimeKey]>=(26695) AND [TimeKey]<=(26722))
)
ON [PRIMARY]
GO