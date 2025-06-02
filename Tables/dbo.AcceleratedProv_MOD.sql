CREATE TABLE [dbo].[AcceleratedProv_MOD] (
  [EntityKey] [bigint] IDENTITY,
  [NCIF_Id] [varchar](20) NULL,
  [SrcSysAlt_Key] [smallint] NULL,
  [CustomerId] [varchar](20) NULL,
  [AccountEntityID] [int] NOT NULL,
  [CustomerACID] [varchar](20) NULL,
  [AccProvPer] [decimal](16, 2) NULL,
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
  [DateApprovedFirstLevel] [smalldatetime] NULL
)
ON [PRIMARY]
GO