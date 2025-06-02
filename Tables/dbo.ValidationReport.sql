CREATE TABLE [dbo].[ValidationReport] (
  [ReportNo] [smallint] NULL,
  [ReportID] [varchar](max) NULL,
  [ReportName] [varchar](max) NULL,
  [ReportType] [varchar](50) NULL,
  [ReportRdlName] [varchar](max) NULL,
  [ReportUrl] [varchar](max) NULL,
  [VersionNo] [varchar](max) NULL,
  [DeptID] [smallint] NULL,
  [DashBoard_ID] [smallint] NULL,
  [Remark] [varchar](max) NULL,
  [RecordStatus] [varchar](1) NULL,
  [EffectiveFromTimeKey] [smallint] NULL,
  [EffectiveToTimeKey] [smallint] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifyBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DeploymentDt] [smalldatetime] NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO