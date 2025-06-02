CREATE TABLE [dbo].[RestructureAccount_DPD_Dec2022] (
  [NCIF_Id] [varchar](15) NULL,
  [CustomerId] [varchar](20) NULL,
  [AccountEntityID] [int] NULL,
  [CustomerACID] [varchar](20) NULL,
  [MaxDPD] [int] NULL,
  [TimeKey] [int] NULL,
  CHECK ([TimeKey]>=(26633) AND [TimeKey]<=(26663))
)
ON [PRIMARY]
GO