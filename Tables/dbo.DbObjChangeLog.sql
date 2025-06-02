CREATE TABLE [dbo].[DbObjChangeLog] (
  [LogID] [int] IDENTITY,
  [DatabaseName] [varchar](256) NULL,
  [SchemaName] [varchar](50) NULL,
  [DbType] [varchar](50) NULL,
  [EventType] [varchar](256) NULL,
  [ObjectName] [varchar](256) NULL,
  [ObjectType] [varchar](50) NULL,
  [SqlCommand] [varchar](max) NULL,
  [LoginName] [varchar](256) NULL,
  [HostName] [varchar](100) NULL,
  [TSql] [varchar](max) NULL,
  [PostTime] [datetime] NULL,
  [ServerName] [varchar](100) NULL,
  [SPID] [varchar](10) NULL,
  [ObjectID] [int] NULL,
  [SchemaID] [int] NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO