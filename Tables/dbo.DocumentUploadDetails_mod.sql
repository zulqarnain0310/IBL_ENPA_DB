CREATE TABLE [dbo].[DocumentUploadDetails_mod] (
  [EntityKey] [int] NOT NULL,
  [MenuId] [int] NULL,
  [DocumentAlt_key] [int] NOT NULL,
  [DocumentTypeAlt_Key] [smallint] NULL,
  [DocLocation] [varchar](200) NULL,
  [DocTitle] [varchar](200) NULL,
  [DocExtn] [varchar](10) NULL,
  [Remark] [varchar](1000) NULL,
  [DocDate] [date] NULL,
  [AuthorisationStatus] [char](2) NULL,
  [EffectiveFromTimeKey] [int] NOT NULL,
  [EffectiveToTimeKey] [int] NOT NULL,
  [CreatedBy] [varchar](20) NOT NULL,
  [DateCreated] [smalldatetime] NOT NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp],
  [NCIF_Id] [varchar](20) NULL,
  [NCIF_EntityID] [int] NULL,
  [DocumentTypeDt] [date] NULL,
  [SrcSysAlt_Key] [smallint] NULL,
  [EntityId] [varchar](10) NULL,
  [CustomerId] [varchar](20) NULL
)
ON [PRIMARY]
GO