CREATE TABLE [dbo].[DedupSysData] (
  [EntityKey] [int] IDENTITY,
  [NCIF] [varchar](20) NULL,
  [SrcAppAlt_Key] [smallint] NULL,
  [SrcAppCustomerID] [varchar](20) NULL,
  [PAN] [varchar](10) MASKED WITH (FUNCTION = 'default()') NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL
)
ON [PRIMARY]
GO