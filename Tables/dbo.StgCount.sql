CREATE TABLE [dbo].[StgCount] (
  [EntityKey] [int] IDENTITY,
  [TimeKey] [int] NULL,
  [SourceName] [varchar](20) NULL,
  [StgCount] [int] NULL,
  [DebitAmount] [decimal](20, 2) NULL,
  [CreditAmount] [decimal](20, 2) NULL,
  [ExecutionStatus] [tinyint] NULL DEFAULT (0)
)
ON [PRIMARY]
GO