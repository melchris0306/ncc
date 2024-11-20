/*******************************************************************************
 * @author       Kyzer Buhay
 * @date         06/01/2021
 * @description  Test class for TheProviderJourney
 * @revision     06/01/2021 - Kyzer Buhay - Created
 *******************************************************************************/
@IsTest
public class GenerateMeetingURL_Test {

    @TestSetup
    static void createData(){
        OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        
        EmailTemplate eTemp = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
        system.runAs( new User(Id = UserInfo.getUserId())){
        	insert eTemp;
        }
        
        Compass_Setting__c setting = new Compass_Setting__c();
        setting.Name = 'Default Settings';
        setting.Email_Sender_Name__c = 'NAME';
        setting.Email_Template_Invitation_Id__c = eTemp.Id;
        setting.Email_Template_Registration_Id__c = eTemp.Id;
        setting.Email_Sender_Id__c = owea.Id;
        insert setting;
        
        Meeting_Application__c meetApp = new Meeting_Application__c();
        meetApp.Name = 'Microsoft Teams';
        meetApp.Live__c = true;
        meetApp.Compass_Setting__c = setting.Id;
        meetApp.Default_Meeting_URL__c = 'teams.meeting.test/01';
        meetApp.Type__c = 'Microsoft Teams';
        insert meetApp;
        
        Campaign__c camp = new Campaign__c();
        camp.Name = 'Test Campaign';
        insert camp;
        
        Event__c e = new Event__c();
        e.Event_Id__c = 'xxxxxxxxxx';
        e.Campaign__c = camp.id;
        e.Start_Date_Time__c = DateTime.Now();
        e.End_Date_Time__c = DateTime.Now().AddDays(1);
        e.Email_Sender_Name__c = 'TEST 123';
        e.Email_Message_CC__c = 'testMail@mail.com';
        e.Email_Message_BCC__c = 'testMail@mail.com';
        e.Email_Sender_Id__c = owea.Id;
        e.Compass_Setting__c = setting.Id;
        insert e;
    }
    
    @IsTest
    static void generateMeetingURLTest(){
        Id eventRecordId = [SELECT Id FROM Event__c LIMIT 1].Id;
        
        Test.startTest();
        	String result = GenerateMeetingURL.generateMeetingURL(eventRecordId, 'Microsoft Teams');
        Test.stopTest();
        System.assertEquals('Meeting URL generated.', result);
    }
    
    @IsTest
    static void retrieveApplicationsTest(){
        Id eventRecordId = [SELECT Id FROM Event__c LIMIT 1].Id;
        
        Test.startTest();
        	GenerateMeetingURL.MeetingApplicationWrapper meetAppWrapper = GenerateMeetingURL.retrieveApplications(eventRecordId);
        Test.stopTest();
        System.assert(meetAppWrapper != null);
    }
}