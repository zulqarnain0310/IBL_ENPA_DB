CREATE TABLE [dbo].[RestructureAccount_DPD_may2023_new] (
  [NCIF_Id] [varchar](15) NULL,
  [CustomerId] [varchar](20) NULL,
  [AccountEntityID] [int] NULL,
  [CustomerACID] [varchar](20) NULL,
  [MaxDPD] [int] NULL,
  [TimeKey] [int] NULL,
  CHECK ([TimeKey]>=(26784) AND [TimeKey]<=(26814))
)
ON [PRIMARY]
GO