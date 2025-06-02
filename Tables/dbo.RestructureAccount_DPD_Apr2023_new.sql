CREATE TABLE [dbo].[RestructureAccount_DPD_Apr2023_new] (
  [NCIF_Id] [varchar](15) NULL,
  [CustomerId] [varchar](20) NULL,
  [AccountEntityID] [int] NULL,
  [CustomerACID] [varchar](20) NULL,
  [MaxDPD] [int] NULL,
  [TimeKey] [int] NULL,
  CHECK ([TimeKey]>=(26754) AND [TimeKey]<=(26783))
)
ON [PRIMARY]
GO