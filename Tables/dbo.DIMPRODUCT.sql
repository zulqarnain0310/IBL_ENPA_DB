CREATE TABLE [dbo].[DIMPRODUCT] (
  [Product_Key] [smallint] NOT NULL,
  [ProductAlt_Key] [smallint] NOT NULL,
  [ProductCode] [varchar](10) NULL,
  [ProductName] [varchar](100) NULL,
  [ProductShortName] [varchar](20) NULL,
  [ProductShortNameEnum] [varchar](20) NULL,
  [ProductGroup] [varchar](50) NULL,
  [ProductSubGroup] [varchar](50) NULL,
  [ProductSegment] [varchar](50) NULL,
  [ProductValidCode] [char](1) NULL,
  [SrcSysProductCode] [varchar](50) NULL,
  [SrcSysProductName] [varchar](50) NULL,
  [DestSysProductCode] [varchar](10) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModifie] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp],
  [AgriFlag] [char](1) NULL DEFAULT ('N')
)
ON [PRIMARY]
GO