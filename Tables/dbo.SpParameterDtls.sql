CREATE TABLE [dbo].[SpParameterDtls] (
  [EntityKey] [int] IDENTITY,
  [ServerName] [varchar](100) NULL,
  [DBName] [varchar](100) NULL,
  [ObjectID] [int] NULL,
  [SchemaID] [int] NULL,
  [SPName] [varchar](250) NULL,
  [SpCreatedDate] [datetime] NULL,
  [SpModifiedDate] [datetime] NULL,
  [ParameterName] [varchar](250) NULL,
  [Type] [varchar](250) NULL,
  [Length] [int] NULL,
  [Prec] [int] NULL,
  [Scale] [int] NULL,
  [Param_order] [int] NULL,
  [Collation] [varchar](100) NULL,
  [ProcessDate] [datetime] NULL
)
ON [PRIMARY]
GO