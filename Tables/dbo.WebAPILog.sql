CREATE TABLE [dbo].[WebAPILog] (
  [D2KTimeStamp] [timestamp] NULL,
  [ResponseType] [varchar](50) NULL,
  [IP] [varchar](50) NULL,
  [Device] [varchar](50) NULL,
  [API] [varchar](50) NULL,
  [Response] [varchar](50) NULL,
  [Status] [varchar](50) NULL,
  [Port] [varchar](20) NULL,
  [Url] [varchar](max) NULL,
  [ServerName] [varchar](50) NULL,
  [Param] [varchar](50) NULL,
  [Token] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO