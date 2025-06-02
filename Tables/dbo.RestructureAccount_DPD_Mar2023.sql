CREATE TABLE [dbo].[RestructureAccount_DPD_Mar2023] (
  [NCIF_Id] [varchar](15) NULL,
  [CustomerId] [varchar](20) NULL,
  [AccountEntityID] [int] NULL,
  [CustomerACID] [varchar](20) NULL,
  [MaxDPD] [int] NULL,
  [TimeKey] [int] NULL,
  CHECK ([TimeKey]>=(26723) AND [TimeKey]<=(26753))
)
ON [PRIMARY]
GO