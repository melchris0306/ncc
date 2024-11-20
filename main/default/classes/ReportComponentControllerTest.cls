/********* 
 * Make sure reports with and without grouping are created
 */
@isTest
private class ReportComponentControllerTest {
    
    @isTest(seeAllData=true) static void testReportMetadata_validIDWParms()
    {
        List<Report> reportList = [ SELECT Id, Name, Format FROM Report where name like '%TESTClass%' limit 10];
        for (report rptObj : reportList)
        {
            // Get the report metadata
        	Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(rptObj.Id);
        	Reports.ReportMetadata reportMd = describe.getReportMetadata();
 
        	Reports.ReportResults results;
        	// Override filter and run report
        	if (reportMd.getReportFilters().size() > 0 )
            {
                List<string> reportFilters = new List<string>();
                reportFilters.add(rptObj.Id);
                reportFilters.add('Name');
                //reportFilters.add(null);
                //reportFilters.add(null);                

                Test.startTest();
            	String reportJSON = ReportComponentController.getReportMetadata(rptObj.Id, true, true, reportFilters);
        		Test.stopTest();

        		Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(reportJSON);
                Map<String, Object> mResults = (Map<String, Object>)m.get('results');
        		Map<String, Object> reportMetadata = (Map<String, Object>)mResults.get('reportMetadata');
        		System.assertEquals( rptObj.Name, reportMetadata.get('name'), 'The correct report should be returned' );
                
                return;
            }
        }        
    }
    
    @isTest(seeAllData=true) static void testReportMetadata_validIDNoParms()
    {
        List<Report> reportList = [ SELECT Id, Name, Format FROM Report where name like '%TESTClass%' limit 10];
        for (report rptObj : reportList)
        {
            // Get the report metadata
        	Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(rptObj.Id);
        	Reports.ReportMetadata reportMd = describe.getReportMetadata();
 
        	Reports.ReportResults results;
        	// Override filter and run report
        	if (reportMd.getReportFilters().size() == 0 )
            {
                List<string> reportFilters = new List<string>();
                reportFilters.add(rptObj.Id);

                Test.startTest();
            	String reportJSON = ReportComponentController.getReportMetadata(rptObj.Id, true, true, reportFilters);
        		Test.stopTest();

        		Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(reportJSON);
                Map<String, Object> mResults = (Map<String, Object>)m.get('results');
        		Map<String, Object> reportMetadata = (Map<String, Object>)mResults.get('reportMetadata');
        		System.assertEquals( rptObj.Name, reportMetadata.get('name'), 'The correct report should be returned' );
                
                return;
            }
        }        
    }

    @isTest static void testReportMetadata_invalidID()
    {
        Id bogusId = '00Q000000000000';
        NoDataFoundException expectedEx;
        String reportJSON;
        try
        {
            List<string> reportFilters = new List<string>();
            reportFilters.add(bogusId);

            Test.startTest();
            reportJSON = ReportComponentController.getReportMetadata(bogusId, true, true, reportFilters);
            Test.stopTest();
        } 
        catch( NoDataFoundException ex )
        {
            expectedEx = ex;
        }

        System.assertEquals( null, reportJSON, 'No report json should be returned' );
        System.assertNotEquals( null, expectedEx, 'An exception should been thronw to be handled by the front-end' );
    }
    
    
    @isTest(seeAllData=true) static void testTabularReportVFPage()
    {
        ReportComponentController vfP;
        List<Report> reportList = [ SELECT Id, Name FROM Report where name like '%TESTClass%' limit 10];
        
        for (report rptObj : reportList)
        {
            ApexPages.currentPage().getParameters().put('reportId', rptObj.Id);
        	ApexPages.currentPage().getParameters().put('recordId', null);
        	ApexPages.currentPage().getParameters().put('showDetails', 'true');
        
        	vfP = new ReportComponentController();
        }   
    }
	
    
    @isTest(seeAllData=true) static void testSummaryReportVFPage()
    {
        ReportComponentController vfP;
        List<Report> reportList = [ SELECT Id, Name FROM Report where name like '%TESTClass%' limit 10];

        for (report rptObj : reportList)
        {
        	ApexPages.currentPage().getParameters().put('reportId', rptObj.Id);
        	ApexPages.currentPage().getParameters().put('recordId', null);
        	ApexPages.currentPage().getParameters().put('showDetails', 'true');
        
        	vfP = new ReportComponentController();
        }
        
    }
}