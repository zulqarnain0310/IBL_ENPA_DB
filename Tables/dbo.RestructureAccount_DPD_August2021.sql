CREATE TABLE [dbo].[RestructureAccount_DPD_August2021] (
  [SrcSysAlt_Key] [smallint] NULL,
  [NCIF_Id] [varchar](15) NULL,
  [NCIF_EntityID] [int] NULL,
  [CustomerId] [varchar](20) NULL,
  [AccountEntityID] [int] NULL,
  [CustomerACID] [varchar](20) NULL,
  [MaxDPD] [int] NULL,
  [TimeKey] [int] NULL,
  CHECK ([TimeKey]>=(26146) AND [TimeKey]<=(26176)),
  CHECK ([TimeKey]>=(26146) AND [TimeKey]<=(26176))
)
ON [PRIMARY]
GO