CREATE TABLE [dbo].[ExcelUploadHistory_bkp19032024] (
  [UniqueUploadID] [int] NOT NULL,
  [UploadedBy] [varchar](100) NULL,
  [DateofUpload] [datetime] NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [UploadType] [varchar](50) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](100) NULL,
  [DateCreated] [datetime] NULL,
  [ModifyBy] [varchar](100) NULL,
  [DateModified] [date] NULL,
  [ApprovedBy] [varchar](100) NULL,
  [DateApproved] [datetime] NULL,
  [D2Ktimestamp] [timestamp],
  [AsOnDate] [date] NULL,
  [ApprovedByFirstLevel] [varchar](20) NULL,
  [DateApprovedFirstLevel] [smalldatetime] NULL
)
ON [PRIMARY]
GO