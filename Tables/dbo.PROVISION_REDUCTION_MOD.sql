CREATE TABLE [dbo].[PROVISION_REDUCTION_MOD] (
  [EntityKey] [bigint] IDENTITY,
  [NCIF_Id] [varchar](20) NULL,
  [SrcSysAlt_Key] [smallint] NULL,
  [CustomerId] [varchar](20) NULL,
  [AccountEntityID] [int] NULL,
  [CustomerACID] [varchar](20) NULL,
  [SECURED_PERCENTAGE] [decimal](8, 5) NULL,
  [UNSECURED_PERCENTAGE] [decimal](8, 5) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NOT NULL,
  [EffectiveToTimeKey] [int] NOT NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [UPLOAdID] [int] NULL,
  [ApprovedByFirstLevel] [varchar](20) NULL,
  [DateApprovedFirstLevel] [smalldatetime] NULL,
  [NCIF_AssetClassAlt_Key] [smallint] NULL
)
ON [PRIMARY]
GO