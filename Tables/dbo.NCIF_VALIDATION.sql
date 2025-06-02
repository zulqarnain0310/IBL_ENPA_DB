CREATE TABLE [dbo].[NCIF_VALIDATION] (
  [Client_ID] [varchar](20) NULL,
  [Source_NCIF] [varchar](20) NULL,
  [ChangedNCIF] [varchar](20) NULL,
  [SrcSysAlt_Key] [int] NULL,
  [NCIF_ValFlag] [char](2) NULL,
  [Timekey] [int] NULL,
  [EntityKey] [int] IDENTITY
)
ON [PRIMARY]
GO