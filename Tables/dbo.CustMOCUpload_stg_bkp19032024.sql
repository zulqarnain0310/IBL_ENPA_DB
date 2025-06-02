CREATE TABLE [dbo].[CustMOCUpload_stg_bkp19032024] (
  [EntityKey] [int] IDENTITY,
  [SrNo] [varchar](max) NULL,
  [AsOnDate] [varchar](10) NULL,
  [NCIF_Id] [varchar](max) NULL,
  [CustomerId] [varchar](max) NULL,
  [CustomerName] [varchar](max) NULL,
  [MOC_AssetClassification] [varchar](max) NULL,
  [MOC_NPADate] [varchar](10) NULL,
  [MOC_SecurityValue] [varchar](max) NULL,
  [AdditionalProvisionPercentage] [varchar](max) NULL,
  [MOC_Reason] [varchar](max) NULL,
  [Remark] [varchar](max) NULL,
  [MOC_Type] [varchar](max) NULL,
  [MOC_Source] [varchar](max) NULL,
  [UploadID] [int] NULL,
  [filname] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO