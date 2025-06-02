CREATE TABLE [dbo].[DimPNPA_Reason] (
  [PNPA_Reason_Key] [smallint] NOT NULL,
  [PNPA_ReasonAlt_Key] [smallint] NULL,
  [PNPA_ReasonSubGroupOrderKey] [tinyint] NULL,
  [PNPA_ReasonOrderKey] [tinyint] NULL,
  [PNPA_ReasonName] [varchar](50) NULL,
  [PNPA_ReasonShortName] [varchar](20) NULL,
  [PNPA_ReasonShortNameEnum] [varchar](20) NULL,
  [PNPA_ReasonGroup] [varchar](50) NULL,
  [PNPA_ReasonSubGroup] [varchar](50) NULL,
  [PNPA_ReasonSegment] [varchar](50) NULL,
  [PNPA_ReasonValidCode] [char](1) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModifie] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp]
)
ON [PRIMARY]
GO