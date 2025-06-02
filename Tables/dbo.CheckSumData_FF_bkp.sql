CREATE TABLE [dbo].[CheckSumData_FF_bkp] (
  [EntityID] [int] IDENTITY,
  [ProcessDate] [date] NULL,
  [Timekey] [int] NULL,
  [SourceName] [nvarchar](50) NULL,
  [SourceAlt_Key] [int] NULL,
  [DataSet] [varchar](3) NULL,
  [CRISMAC_CheckSum] [nvarchar](100) NULL,
  [Source_CheckSum] [nvarchar](100) NULL,
  [Start_BAU] [char](1) NULL,
  [Processing_Type] [varchar](10) NULL,
  [Reason] [varchar](max) NULL,
  [AuthorisationStatus] [char](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedByFirstLevel] [varchar](100) NULL,
  [DateApprovedFirstLevel] [datetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp]
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO