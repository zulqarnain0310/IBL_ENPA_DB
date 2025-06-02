CREATE TABLE [dbo].[DimuserDeptGroup_17062023] (
  [EntityKey] [smallint] IDENTITY,
  [DeptGroupId] [smallint] NULL,
  [DeptGroupCode] [varchar](12) NULL,
  [DeptGroupName] [varchar](200) NULL,
  [Menus] [varchar](1000) NULL,
  [IsUniversal] [char](1) NULL,
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
  [SourceAlt_Key] [varchar](50) NULL
)
ON [PRIMARY]
GO