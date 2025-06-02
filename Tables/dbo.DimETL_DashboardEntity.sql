CREATE TABLE [dbo].[DimETL_DashboardEntity] (
  [ETL_DashboardEntity_Key] [smallint] IDENTITY,
  [ETL_DashboardEntityAlt_Key] [smallint] NOT NULL,
  [ETL_DashboardEntityName] [varchar](100) NOT NULL,
  [ETL_DashboardEntityShortName] [varchar](20) NULL,
  [ETL_DashboardEntityShortNameEnum] [varchar](20) NULL,
  [ETL_DashboardEntityGroup] [varchar](50) NULL,
  [ETL_DashboardEntitySubGroup] [varchar](50) NULL,
  [ETL_DashboardEntitySegment] [varchar](50) NULL,
  [ETL_DashboardEntityValidCode] [char](1) NULL,
  [SrcSysETL_DashboardEntityName] [varchar](100) NOT NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NOT NULL,
  [EffectiveToTimeKey] [int] NOT NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp]
)
ON [PRIMARY]
GO