@istest
public with sharing class importSurveyDataControllerTest 
{
    @isTest 
    static void importDataSaveFileTest() 
    {
        campaign__c campaignO = new campaign__c(name='Test Campaign');
        insert campaignO;
            
        Compass_Setting__c comp = TestDataFactory.createCSData(1);
        insert comp;
        
        event__c eventO = new event__c(name='Test Event', campaign__c=campaignO.Id);
        insert eventO;
        
        session__c sessionO = new session__c(name='Test Session', event__c=eventO.Id);
        insert sessionO;
        
        string surveyQuestions = '\"Name,Sorting_Order__c,Question_Type__c,Options__c\\r\\n' +
            'I was able to attend the entire scenario block.,1,Radio,\\"Yes\\nNo\\"\\r\\n\"';
        string surveyAnswers ='\"Response #,Survey,Facility,Session,1\\r\\n249,Test Survey,Test Event, Test Session,Yes\\r\\n250,Test Survey,Test EventX, Test Session,Yes\\r\\n249,Test Survey,Test Event, Test Session,Yes\\r\\n\"';
        string surveyAnswers1 ='\"Response #,Survey,Facility,Session,1\\r\\n249,Test Survey,Test EventX, Test Session,Yes\\r\\n250,Test Survey,Test EventX, Test Session,Yes\\r\\n249,Test Survey,Test EventX, Test Session,Yes\\r\\n\"';
        
        Test.startTest();
        Test.setMock(HTTPCalloutMock.class, new FlowCallout_Test.ValidCallout()); 
        
        // Test survey Answers & questions
        importSurveyDataController.saveFile(surveyQuestions,surveyAnswers1);
        
        // Test survey Answers & questions
        importSurveyDataController.saveFile(surveyQuestions,surveyAnswers);
        
        // Test survey Answers & questions
        importSurveyDataController.saveFile(surveyQuestions,surveyAnswers);
        
        Test.stopTest();
        
    }
}