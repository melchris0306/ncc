@istest
public with sharing class reportCategoryTest {
    @TestSetup
    static void makeData(){
        
        List<Apex_Trigger_Switch__c> switchRecs = TestDataFactory.createAllTriggerSwitch();
        insert switchRecs;
        
        Campaign c = TestFactory.createCampaign('Test Campaign', 'Event');
        
        Journey__c testJourney = new Journey__c(Name='TestJourney');
        insert testJourney;
        
        Compass_Setting__c comp = TestDataFactory.createCSData(1);
        insert comp;
        
        Event__c newEvent = TestFactory.createEvent('Test Campaign');
        Survey__c newSurvey = TestFactory.createSurvey(newEvent.Id, 'Test Survey');
        newSurvey.Journey__c = testJourney.Id;
        newSurvey.Survey_Campaign__c = c.Id;
        
        Survey_Question__c sq = TestFactory.createSurveyQuestion(newSurvey.Id, 'What is your name?', 'Radio', 1);
        sq.Report_Category__c = 'Yes';
        sq.Options__c = 'Yes' +  '\n' + 'No';
        update sq;
        //Account newPersonAccount = TestFactory.createPersonAccount('John', 'Doe', 'j.doe@gmail.com');
        Survey_Response__c testSR = TestFactory.createSurveyResponse(newEvent.Id, newSurvey.Id, null);
        
        Test.setMock(HTTPCalloutMock.class, new FlowCallout_Test.ValidCallout());
        
        Survey_Answer__c testSA = TestFactory.createSurveyAnswer(testSR.Id, 'Do you have a car? ', 'Yes');
        testSA.Survey_Question__c = sq.id;
        update testSA;
    }

    @isTest
    public static void testreportCategoryEvent(){
        Event__c cp = [SELECT Id FROM Event__c WHERE Name = 'Test Campaign'];
        Test.startTest();
        Test.setMock(HTTPCalloutMock.class, new FlowCallout_Test.ValidCallout());
        reportCategory.getRecords(cp.id);
        reportCategory.updReportCategory(cp.id);
        Test.stopTest();
    }
    
	@isTest
    public static void testreportCategoryCampaign(){
        Campaign cp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign'];
        Test.startTest();
        Test.setMock(HTTPCalloutMock.class, new FlowCallout_Test.ValidCallout());
        reportCategory.updReportCategory(cp.id);
        Test.stopTest();
    }
    
    @isTest
    public static void testreportCategoryJourney(){
        Journey__c j = [SELECT Id FROM Journey__c WHERE Name = 'TestJourney'];
        Test.startTest();
        Test.setMock(HTTPCalloutMock.class, new FlowCallout_Test.ValidCallout());
        reportCategory.updReportCategory(j.id);
        Test.stopTest();
    }
}