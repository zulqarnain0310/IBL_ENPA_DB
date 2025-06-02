CREATE TABLE [dbo].[NCIF_ModificationDetail] (
  [EntityKey] [int] NOT NULL,
  [SrcSysAlt_Key] [tinyint] NULL,
  [CustomerID] [varchar](20) NULL,
  [CustomerACID] [varchar](20) MASKED WITH (FUNCTION = 'default()') NULL,
  [OldNCIF] [varchar](20) NULL,
  [NewNCIF] [varchar](20) NULL,
  [NCIF_chnageDate] [datetime] NULL
)
ON [PRIMARY]
GO