CREATE TABLE [dbo].[RestructureAccount_DPD_OCT2021] (
  [NCIF_Id] [varchar](15) NULL,
  [CustomerId] [varchar](20) NULL,
  [AccountEntityID] [int] NULL,
  [CustomerACID] [varchar](20) NULL,
  [MaxDPD] [int] NULL,
  [TimeKey] [int] NULL,
  CHECK ([TimeKey]>=(26207) AND [TimeKey]<=(26237))
)
ON [PRIMARY]
GO