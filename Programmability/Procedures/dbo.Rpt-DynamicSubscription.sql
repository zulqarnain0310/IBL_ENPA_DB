SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
 Create Proc [dbo].[Rpt-DynamicSubscription]
 AS
 
 Select
 
 'http://' + 'Server2016' + '/ReportServer/Pages/ReportViewer.aspx?%2F'
 + REPLACE(REPLACE('IndusInd Report',' ','+'),'/','%2F') + '%2F' 
+ REPLACE(REPLACE('Rpt-16-Potential NPAs',' ','+'),'/','%2F') + '%2F'
+ '&DtEnter=' + '31-01-2018' + '&Cost=' +'1' + '&DimsourceSystem=' + '0' +'&rs:command=Render&rs:Format=PDF'   
 AS ReportURL
GO