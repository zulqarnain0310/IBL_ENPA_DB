CREATE TABLE [dbo].[SpLogDtls] (
  [EntityKey] [int] IDENTITY,
  [ObjectID] [int] NULL,
  [SchemaID] [int] NULL,
  [SPName] [varchar](max) NULL,
  [SpDateModified_V1] [datetime] NULL,
  [SpDateModified_V2] [datetime] NULL,
  [ScriptStatus] [varchar](100) NULL,
  [ProcessDate] [datetime] NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO