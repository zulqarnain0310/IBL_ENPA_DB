CREATE TABLE [dbo].[WriteOffDataUpload_Mod] (
  [SRNO] [int] IDENTITY,
  [SrcSysAlt_Key] [smallint] NULL,
  [NCIF_Id] [varchar](30) NULL,
  [CustomerID] [varchar](50) NULL,
  [CustomerAcID] [varchar](30) MASKED WITH (FUNCTION = 'default()') NULL,
  [WriteOffDate] [date] NULL,
  [WO_PWO] [char](3) NULL,
  [POSWriteOffAmount] [decimal](18, 2) NULL,
  [InttWriteOffAmount] [decimal](18, 2) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp],
  [Action] [varchar](5) NULL
)
ON [PRIMARY]
GO