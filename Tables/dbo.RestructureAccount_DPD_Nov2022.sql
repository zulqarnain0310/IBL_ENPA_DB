CREATE TABLE [dbo].[RestructureAccount_DPD_Nov2022] (
  [NCIF_Id] [varchar](15) NULL,
  [CustomerId] [varchar](20) NULL,
  [AccountEntityID] [int] NULL,
  [CustomerACID] [varchar](20) NULL,
  [MaxDPD] [int] NULL,
  [TimeKey] [int] NULL,
  CHECK ([TimeKey]>=(26603) AND [TimeKey]<=(26632))
)
ON [PRIMARY]
GO