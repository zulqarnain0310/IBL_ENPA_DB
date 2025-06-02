CREATE TABLE [dbo].[Package_AUDIT_30092023_1] (
  [Execution_date] [date] NULL,
  [DataBaseName] [nvarchar](30) NULL,
  [PackageName] [nvarchar](100) NOT NULL,
  [TableName] [nvarchar](100) NOT NULL,
  [ExecutionStartTime] [smalldatetime] NULL,
  [ExecutionEndTime] [smalldatetime] NULL,
  [TimeDuration_Min] [int] NULL,
  [ExecutionStatus] [nvarchar](10) NOT NULL
)
ON [PRIMARY]
GO