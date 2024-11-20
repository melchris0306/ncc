@isTest
public class SurveyAnswerTriggerHandler_Test {
    @TestSetup
    static void makeData(){
        List<Apex_Trigger_Switch__c> switchRecs = TestDataFactory.createAllTriggerSwitch();
        insert switchRecs;
        Test.setMock(HTTPCalloutMock.class, new FlowCallout_Test.ValidCallout());
		Event__c newCampaign = TestFactory.createEvent('Test Campaign');
		Survey__c newSurvey = TestFactory.createSurvey(newCampaign.Id, 'Test Survey');
		Survey_Question__c sq = TestFactory.createSurveyQuestion(newSurvey.Id, 'What is your name?', 'Text', 1);
		Account newPersonAccount = TestFactory.createPersonAccount('John', 'Doe','j.doe@gmail.com');
		Contact c = TestFactory.createContact('John', 'Doe', 'john.doe@gmail.com');
		String contactStr = '{"Contact|FirstName":"John","Contact|LastName":"Doe","Contact|Email":"john.doe@gmail.com"}';
		String resultStr = '{"' + sq.Id + '":{"Question":"Select a value between 1 to 5","Answer":"4"}}';
		Event__c cp = [SELECT Id, Event_Id__c FROM Event__c WHERE ID = :newCampaign.Id LIMIT 1];
		
        //replaced call from CCESurveyController to avoid dependency to another class that isn't a test helper class
        Survey_Response__c surveyResp = TestFactory.createSurveyResponse(cp.Id, newSurvey.Id, newPersonAccount.Id);
        TestFactory.createSurveyAnswer(surveyResp.Id, 'What is your name?', 'Test Answer');
    }

    @IsTest
    static void test_program_flow(){
        Event__c evt = [SELECT ID FROM Event__c LIMIT 1];
        Survey__c survey = [SELECT ID FROM Survey__c LIMIT 1];
        Account acc = [SELECT ID FROM Account LIMIT 1];
        Test.setMock(HTTPCalloutMock.class, new FlowCallout_Test.ValidCallout());
        Test.startTest();
            Survey_Response__c surveyResp = TestFactory.createSurveyResponse(evt.Id, survey.Id, acc.Id);
            Survey_Answer__c answer = TestFactory.createSurveyAnswer(surveyResp.Id, 'What is your name?', 'Test Answer');
            Update answer;
        Test.stopTest();
        
    }
}