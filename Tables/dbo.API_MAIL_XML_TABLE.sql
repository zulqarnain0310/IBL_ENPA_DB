CREATE TABLE [dbo].[API_MAIL_XML_TABLE] (
  [RefId] [varchar](100) NULL,
  [Txncode] [varchar](100) NULL,
  [Emailid] [varchar](100) NULL,
  [Subject] [varchar](250) NULL,
  [Msg] [varchar](max) NULL,
  [ASONDATE] [date] NULL,
  [EFFECTIVEFROMTIMEKEY] [int] NULL,
  [EFFECTIVETOTIMEKEY] [int] NULL,
  [ChnlId] [varchar](50) NULL,
  [Key] [varchar](50) NULL,
  [DATE] [datetime] NULL,
  [ResponseText] [varchar](500) NULL,
  [MSG1] [varchar](250) NULL,
  [MSG2] [varchar](250) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO