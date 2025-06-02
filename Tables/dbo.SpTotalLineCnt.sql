CREATE TABLE [dbo].[SpTotalLineCnt] (
  [EntityKey] [int] IDENTITY,
  [ServerName] [varchar](50) NULL,
  [DatabaseName] [varchar](150) NULL,
  [ObjectID] [int] NULL,
  [SchemaID] [int] NULL,
  [Routine_Type] [varchar](250) NULL,
  [Object_Name] [varchar](500) NULL,
  [Lines_Of_Code] [int] NULL,
  [CreatedDate] [datetime] NULL,
  [ModifiedDate] [datetime] NULL,
  [ProcessDate] [datetime] NULL
)
ON [PRIMARY]
GO