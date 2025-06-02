CREATE TABLE [dbo].[UploadBranch_Master_Upload] (
  [EntityKey] [int] IDENTITY,
  [SrNo] [varchar](max) NULL,
  [UploadID] [int] NULL,
  [BranchCode] [varchar](max) NULL,
  [BranchName] [varchar](max) NULL,
  [AddLine1] [varchar](max) NULL,
  [AddLine2] [varchar](max) NULL,
  [AddLine3] [varchar](max) NULL,
  [Place] [varchar](max) NULL,
  [PinCode] [varchar](max) NULL,
  [BranchOpenDt] [varchar](30) NULL,
  [BranchAreaCategory] [varchar](max) NULL,
  [BranchStateName] [varchar](max) NULL,
  [BranchDistrictName] [varchar](max) NULL,
  [Action] [varchar](max) NULL,
  [FileName] [varchar](max) NULL,
  [ErrorMessage] [varchar](max) NULL,
  [ErrorinColumn] [varchar](max) NULL,
  [Srnooferroneousrows] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO