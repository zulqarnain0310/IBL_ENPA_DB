CREATE TABLE [dbo].[TableDependencyDtls] (
  [EntityKey] [int] IDENTITY,
  [ServerName] [varchar](50) NULL,
  [ServerType] [varchar](50) NULL,
  [DbName] [varchar](100) NULL,
  [ObjectID] [int] NULL,
  [SchemaID] [int] NULL,
  [SpName] [varchar](250) NULL,
  [TableName] [varchar](250) NULL,
  [SpCreatedDate] [datetime] NULL,
  [SpModifiedDate] [datetime] NULL,
  [TableInfo] [varchar](50) NULL,
  [DatabaseInfo] [varchar](50) NULL,
  [ProcessDate] [datetime] NULL
)
ON [PRIMARY]
GO