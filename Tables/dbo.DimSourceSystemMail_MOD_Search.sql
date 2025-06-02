CREATE TABLE [dbo].[DimSourceSystemMail_MOD_Search] (
  [SourceSystem] [varchar](50) NULL,
  [EMailID] [nvarchar](50) NULL,
  [IsActive] [nvarchar](50) NULL,
  [OperationBy] [nvarchar](50) NULL,
  [OperationDate] [datetime2] NULL,
  [AuthorisationStatus] [nvarchar](50) NULL,
  [CrModBy] [nvarchar](50) NULL,
  [ModAppBy] [nvarchar](50) NULL,
  [CrAppBy] [nvarchar](50) NULL,
  [FirstLevelApprovedBy] [nvarchar](50) NULL,
  [TableName] [varchar](16) NOT NULL
)
ON [PRIMARY]
GO