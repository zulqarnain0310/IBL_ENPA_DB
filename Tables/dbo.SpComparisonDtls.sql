CREATE TABLE [dbo].[SpComparisonDtls] (
  [EntityKey] [int] IDENTITY,
  [ObjectID] [int] NULL,
  [SchemaID] [int] NULL,
  [SpName] [varchar](250) NULL,
  [SpCreatedBy] [varchar](100) NULL,
  [SpCreatedDate] [datetime] NULL,
  [SpCode_v1] [varchar](max) NULL,
  [SpLineNo_v1] [int] NULL,
  [SpModifiedDate_v1] [datetime] NULL,
  [SpModifiedBy_v1] [varchar](100) NULL,
  [SpCode_v2] [varchar](max) NULL,
  [SpLineNo_v2] [int] NULL,
  [SpModifiedDate_v2] [datetime] NULL,
  [SpModifiedBy_v2] [varchar](100) NULL,
  [ProcessDate] [datetime] NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO