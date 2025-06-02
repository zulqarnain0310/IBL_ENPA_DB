CREATE TABLE [CURDAT].[AdvAcWODetail] (
  [EntityKey] [bigint] IDENTITY,
  [BranchCode] [varchar](10) NULL,
  [CustomerEntityId] [int] NULL,
  [AccountEntityId] [int] NULL,
  [CustomerID] [varchar](30) NULL,
  [CustomerName] [varchar](80) NULL,
  [SystemACID] [varchar](30) NULL,
  [CustomerACID] [varchar](30) MASKED WITH (FUNCTION = 'default()') NULL,
  [SrcSysAlt_Key] [smallint] NULL,
  [NCIF_Id] [varchar](20) NULL,
  [WOEntityID] [int] NULL,
  [RestructureEntityID] [int] NULL,
  [GLAlt_Key] [int] NULL,
  [ProductAlt_Key] [smallint] NULL,
  [GLProductAlt_Key] [smallint] NULL,
  [FacilityType] [varchar](10) NULL,
  [SectorAlt_Key] [smallint] NULL,
  [SubSectorAlt_Key] [smallint] NULL,
  [ActivityAlt_Key] [smallint] NULL,
  [SchemeAlt_Key] [smallint] NULL,
  [AssetClassAlt_Key] [smallint] NULL,
  [NPADt] [date] NULL,
  [WO_PWO] [char](3) NULL,
  [WriteOffDt] [date] NULL,
  [WriteOffAmt] [decimal](18, 2) NULL,
  [SettlementAmt] [decimal] NULL,
  [SettlementDt] [date] NULL,
  [RecompenseAmt] [decimal] NULL,
  [RecompenseDt] [date] NULL,
  [SacrificeAmt] [decimal] NULL,
  [IntSacrifice] [decimal](18, 2) NULL,
  [FITLSacrifice] [decimal] NULL,
  [OthSacrifice] [decimal] NULL,
  [FITLAccountRefNo] [varchar](20) NULL,
  [AuthorisationStatus] [char](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp],
  [Action] [varchar](5) NULL,
  [UploadId] [int] NULL,
  [UploadType] [varchar](100) NULL,
  [UploadTypeParameterAlt_Key] [int] NULL,
  [Customer_CIF] [varchar](20) NULL,
  CONSTRAINT [PK_AdvAcWODetail_copy] PRIMARY KEY NONCLUSTERED ([EntityKey]) WITH (PAD_INDEX = ON, FILLFACTOR = 80)
)
ON [PRIMARY]
GO

CREATE CLUSTERED INDEX [AdvAcWODetail_IX]
  ON [CURDAT].[AdvAcWODetail] ([EntityKey])
  ON [PRIMARY]
GO

CREATE INDEX [AdvAcWODetail_NONIX]
  ON [CURDAT].[AdvAcWODetail] ([EffectiveFromTimeKey], [EffectiveToTimeKey], [CustomerID], [CustomerACID], [WriteOffDt], [WriteOffAmt])
  ON [PRIMARY]
GO