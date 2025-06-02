CREATE TABLE [dbo].[Log_APIAudit_20241212] (
  [EntityKey] [int] IDENTITY,
  [PAN] [varchar](10) NULL,
  [RecordCount] [int] NULL,
  [Date] [date] NULL,
  [Time] [time] NULL,
  [Remark] [varchar](1000) NULL,
  [NCIF_Id] [varchar](20) NULL
)
ON [PRIMARY]
GO