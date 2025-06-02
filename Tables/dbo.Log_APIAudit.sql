CREATE TABLE [dbo].[Log_APIAudit] (
  [EntityKey] [int] IDENTITY,
  [PAN] [varchar](max) NULL,
  [RecordCount] [int] NULL,
  [Date] [date] NULL,
  [Time] [time] NULL,
  [Remark] [varchar](1000) NULL,
  [NCIF_Id] [varchar](20) NULL,
  [AADHAR] [varchar](2000) NULL,
  [VOTERID] [varchar](2000) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO