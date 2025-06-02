CREATE TABLE [dbo].[SpTableDependencyDtls] (
  [EntityKey] [int] IDENTITY,
  [MainDBName] [varchar](100) NULL,
  [ServerName] [varchar](150) NULL,
  [ServerType] [varchar](20) NULL,
  [ObjectID] [int] NULL,
  [SchemaID] [int] NULL,
  [ReferencedDBName] [varchar](100) NULL,
  [ReferencedTableName] [varchar](500) NULL,
  [ReferencedSchemaName] [varchar](150) NULL,
  [ReferencedColumnName] [varchar](500) NULL,
  [IsUpdate] [bit] NULL,
  [IsSelect] [bit] NULL,
  [IsAllColumnsFound] [bit] NULL,
  [IsCallerDependent] [bit] NULL,
  [SpName] [varchar](500) NULL,
  [SpCreatedDate] [datetime] NULL,
  [SpModifiedDate] [datetime] NULL,
  [TableCreatedDate] [datetime] NULL,
  [TableModifiedDate] [datetime] NULL,
  [ProcessDateTime] [datetime] NOT NULL
)
ON [PRIMARY]
GO