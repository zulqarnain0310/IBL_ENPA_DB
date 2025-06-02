CREATE TABLE [dbo].[RestructureAccount_DPD_Jan2023new] (
  [NCIF_Id] [varchar](15) NULL,
  [CustomerId] [varchar](20) NULL,
  [AccountEntityID] [int] NULL,
  [CustomerACID] [varchar](20) NULL,
  [MaxDPD] [int] NULL,
  [TimeKey] [int] NULL,
  CHECK ([TimeKey]>=(26664) AND [TimeKey]<=(26694))
)
ON [PRIMARY]
GO