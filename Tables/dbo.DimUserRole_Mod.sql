CREATE TABLE [dbo].[DimUserRole_Mod] (
  [UserRole_Key] [smallint] IDENTITY,
  [UserRoleAlt_Key] [smallint] NULL,
  [UserRoleName] [varchar](20) NULL,
  [UserRoleShortName] [varchar](20) NULL,
  [UserRoleShortNameEnum] [varchar](20) NULL,
  [UserRoleGroup] [varchar](50) NULL,
  [UserRoleSubGroup] [varchar](50) NULL,
  [UserRoleSegment] [varchar](50) NULL,
  [UserRoleValidCode] [char](1) NULL,
  [SrcSysUserRoleCode] [varchar](50) NULL,
  [SrcSysUserRoleName] [varchar](50) NULL,
  [DestSysUserRoleCode] [varchar](10) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [ApprovedByFirstLevel] [varchar](100) NULL,
  [DateApprovedFirstLevel] [datetime] NULL,
  [D2Ktimestamp] [timestamp],
  [ChangeFields] [varchar](1000) NULL
)
ON [PRIMARY]
GO