CREATE TABLE [dbo].[DimSourceSystemMail_MOD_DISPLAY] (
  [SourceSystem] [varchar](50) NULL,
  [EMailID] [nvarchar](50) NULL,
  [IsActive] [nvarchar](50) NULL,
  [OperationBy] [nvarchar](50) NULL,
  [OperationDate] [datetime2] NULL,
  [AuthorisationStatus] [nvarchar](50) NOT NULL,
  [CrModBy] [nvarchar](50) NULL,
  [ModAppBy] [nvarchar](50) NULL,
  [CrAppBy] [nvarchar](50) NULL,
  [FirstLevelApprovedBy] [nvarchar](50) NULL
)
ON [PRIMARY]
GO