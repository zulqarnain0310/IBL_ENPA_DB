CREATE TABLE [dbo].[DimSourceSystemMail] (
  [SourceSystemMail_Key] [tinyint] NOT NULL,
  [SourceAlt_Key] [tinyint] NULL,
  [SourceSystemMailID] [nvarchar](50) NULL,
  [SourceSystemMailGroup] [nvarchar](50) NULL,
  [SourceSystemMailSubGroup] [nvarchar](50) NULL,
  [SourceSystemMailSegment] [nvarchar](50) NULL,
  [SourceSystemMailValidCode] [nvarchar](50) NULL,
  [AuthorisationStatus] [nvarchar](50) NULL,
  [EffectiveFromTimeKey] [smallint] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [nvarchar](50) NULL,
  [DateCreated] [datetime2] NULL,
  [ModifiedBy] [nvarchar](50) NULL,
  [DateModified] [nvarchar](50) NULL,
  [ApprovedBy] [nvarchar](50) NULL,
  [DateApproved] [nvarchar](50) NULL,
  [D2Ktimestamp] [nvarchar](50) NOT NULL,
  [ApprovedByFirstLevel] [nvarchar](50) NULL,
  [DateApprovedFirstLevel] [nvarchar](50) NULL
)
ON [PRIMARY]
GO