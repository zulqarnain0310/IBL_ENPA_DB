CREATE TABLE [dbo].[SysCRisMacMenu_21032025] (
  [EntityKey] [int] NOT NULL,
  [MenuTitleId] [int] NULL,
  [DataSeq] [int] NULL,
  [MenuId] [int] NULL,
  [ParentId] [int] NULL,
  [MenuCaption] [nvarchar](300) NULL,
  [ActionName] [varchar](50) NULL,
  [Viewpath] [varchar](50) NULL,
  [ngController] [varchar](50) NULL,
  [BusFld] [nvarchar](1) NULL,
  [ThirdGroup] [nvarchar](1) NULL,
  [ApplicableFor] [nvarchar](5) NULL,
  [Visible] [bit] NOT NULL,
  [ReportId] [varchar](400) NULL,
  [AvailableFor] [varchar](80) NULL,
  [NonAllowOperation] [varchar](3) NULL,
  [DeptGroupCode] [varchar](max) NULL,
  [EnableMakerChecker] [char](1) NULL,
  [ResponseTimeDisplay] [char](1) NULL,
  [Deptartment] [char](200) NULL,
  [SaveWithCER] [char](1) NULL,
  [ExecutionCer] [char](1) NULL,
  [AccessLevel] [varchar](20) NULL,
  [GridApplicable] [char](1) NULL,
  [Accordian] [char](1) NULL,
  [AuthLevel] [int] NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO