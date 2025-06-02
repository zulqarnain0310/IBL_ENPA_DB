CREATE TABLE [dbo].[Package_AUDIT] (
  [Execution_date] [date] NULL,
  [DataBaseName] [nvarchar](30) NULL,
  [PackageName] [nvarchar](100) NOT NULL,
  [TableName] [nvarchar](100) NOT NULL,
  [ExecutionStartTime] [smalldatetime] NULL,
  [ExecutionEndTime] [smalldatetime] NULL,
  [TimeDuration_Min] AS (datediff(minute,[ExecutionStartTime],[ExecutionEndTime])),
  [ExecutionStatus] [nvarchar](10) NOT NULL
)
ON [PRIMARY]
GO