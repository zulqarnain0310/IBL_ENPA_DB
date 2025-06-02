CREATE TABLE [dbo].[CustMOCUpload_stg] (
  [EntityKey] [int] IDENTITY,
  [SrNo] [varchar](50) NULL,
  [AsOnDate] [varchar](50) NULL,
  [NCIF_Id] [varchar](50) NULL,
  [CustomerId] [varchar](50) NULL,
  [CustomerName] [varchar](50) NULL,
  [MOC_AssetClassification] [varchar](50) NULL,
  [MOC_NPADate] [varchar](50) NULL,
  [MOC_SecurityValue] [varchar](50) NULL,
  [AdditionalProvisionPercentage] [varchar](50) NULL,
  [MOC_Reason] [varchar](50) NULL,
  [Remark] [varchar](50) NULL,
  [MOC_Type] [varchar](50) NULL,
  [MOC_Source] [varchar](50) NULL,
  [UploadID] [varchar](50) NULL,
  [filname] [varchar](50) NULL,
  [LossDate] [varchar](50) NULL,
  [DBTDate] [varchar](50) NULL
)
ON [PRIMARY]
GO