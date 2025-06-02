CREATE TABLE [dbo].[RestructureAccount_DPD_Aug2022] (
  [SrcSysAlt_Key] [smallint] NULL,
  [NCIF_Id] [varchar](15) NULL,
  [NCIF_EntityID] [int] NULL,
  [CustomerId] [varchar](20) NULL,
  [AccountEntityID] [int] NULL,
  [CustomerACID] [varchar](20) NULL,
  [MaxDPD] [int] NULL,
  [TimeKey] [int] NULL,
  CHECK ([TimeKey]>=(26511) AND [TimeKey]<=(26541))
)
ON [PRIMARY]
GO