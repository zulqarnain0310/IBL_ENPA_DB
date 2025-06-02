CREATE TABLE [dbo].[DimPackageAudit] (
  [Package_Key] [smallint] NOT NULL,
  [PackageAlt_Key] [smallint] NOT NULL,
  [PackageName] [varchar](100) NULL,
  [PackageDescriptionName] [varchar](150) NULL,
  [PackageShortNameEnum] [varchar](20) NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModifie] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp]
)
ON [PRIMARY]
GO