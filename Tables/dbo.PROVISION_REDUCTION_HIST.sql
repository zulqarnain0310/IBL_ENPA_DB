CREATE TABLE [dbo].[PROVISION_REDUCTION_HIST] (
  [EntityKey] [bigint] NULL,
  [NCIF_Id] [varchar](20) NULL,
  [SrcSysAlt_Key] [smallint] NULL,
  [CustomerId] [varchar](20) NULL,
  [AccountEntityID] [int] NULL,
  [CustomerACID] [varchar](20) NULL,
  [SECURED_PERCENTAGE] [decimal](8, 5) NULL,
  [UNSECURED_PERCENTAGE] [decimal](8, 5) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [UploadId] [int] NULL,
  [NCIF_AssetClassAlt_Key] [smallint] NULL
)
ON [PRIMARY]
GO