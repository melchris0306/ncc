@isTest
public class SurveyParticipantTriggerTest {
    
    @TestSetup
    static void makeData(){
        Event__c testEvent = TestFactory.createEvent('Test Campaign');
        TestFactory.createEvent('Test Campaign 2');
        Survey__c testActiveSurvey1 = TestFactory.createSurvey(testEvent.Id, 'Test Active Survey 1');
        
        Contact cont = TestFactory.createContact('Test', 'Contact', 'testcontact@gmail.com');
    }
    
    // Added by RLugpatan [CCN-1049] Jan062022
    @isTest
    public static void testSyncSurveyRichTextFields(){
        Survey__c testSurvey = [SELECT Id FROM Survey__c WHERE Name =: 'Test Active Survey 1' LIMIT 1];
        Contact cont = [Select Id From Contact LIMIT 1];
        
        Test.startTest();
        
        // Update Survey record
        testSurvey.Survey_Thank_You_Message__c = 'Test Survey Thank you Message';
        testSurvey.Survey_Catchup_Message__c = 'Test Survey Catchup Message';
        testSurvey.Survey_Catchup_Reminder_Message__c = 'Test Survey Catchup Reminder Message';
        testSurvey.Survey_Reminder_Message__c = 'Test Survey Reminder Message';
        update testSurvey;
        
        Survey_Participant__c surveyParticipant = new Survey_Participant__c();
        surveyParticipant.Survey__c = testSurvey.Id;
        surveyParticipant.Participant__c = cont.Id;
        insert surveyParticipant;
        
        Test.stopTest();
        
        Survey_Participant__c surveyParticipantChecking = [SELECT Id, Survey_Thank_You_Message__c, Survey_Catchup_Reminder_Message__c, Survey_Catchup_Message__c, 
                                                   Survey_Reminder_Message__c, Survey__r.Survey_Thank_You_Message__c, Survey__r.Survey_Catchup_Reminder_Message__c, 
                                                   Survey__r.Survey_Catchup_Message__c, Survey__r.Survey_Reminder_Message__c
                                                   FROM Survey_Participant__c WHERE Id = :surveyParticipant.Id]; 
        System.assertEquals(surveyParticipantChecking.Survey_Thank_You_Message__c, surveyParticipantChecking.Survey__r.Survey_Thank_You_Message__c);
        System.assertEquals(surveyParticipantChecking.Survey_Catchup_Message__c, surveyParticipantChecking.Survey__r.Survey_Catchup_Message__c);
        System.assertEquals(surveyParticipantChecking.Survey_Catchup_Reminder_Message__c, surveyParticipantChecking.Survey__r.Survey_Catchup_Reminder_Message__c);
        System.assertEquals(surveyParticipantChecking.Survey_Reminder_Message__c, surveyParticipantChecking.Survey__r.Survey_Reminder_Message__c);
    }
}