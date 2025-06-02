CREATE TABLE [dbo].[SpDtls] (
  [EntityKey] [int] IDENTITY,
  [ObjectID] [int] NULL,
  [SchemaID] [int] NULL,
  [Spcode] [varchar](max) NULL,
  [Spname] [varchar](max) NULL,
  [LineNumber] [int] NULL,
  [SpCreatedDate] [datetime] NULL,
  [SpModifiedDate] [datetime] NULL,
  [CreatedBy] [varchar](250) NULL,
  [ModifiedBy] [varchar](250) NULL,
  [ProcessDate] [datetime] NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO