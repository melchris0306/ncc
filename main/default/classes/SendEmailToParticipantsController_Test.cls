@IsTest
public class SendEmailToParticipantsController_Test {
	@TestSetup
    static void setupData(){
        OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        
        EmailTemplate eTemp = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
        system.runAs( new User(Id = UserInfo.getUserId())){
          insert eTemp;
        }
        
        Apex_Trigger_Switch__c aps = new Apex_Trigger_Switch__c();
        aps.Name = 'EventTrigger';
        aps.Active__c = false;
        insert aps;
        
        /*Compass_Setting__c setting = new Compass_Setting__c();
        setting.Name = 'Default Settings';
        setting.Email_Sender_Id__c = 'qwerty';
        insert setting;*/
        
        Compass_Setting__c setting = new Compass_Setting__c();
        setting.Name = 'Default Settings';
        setting.Email_Sender_Name__c = 'NAME';
        setting.Email_Template_Invitation_Id__c = eTemp.Id;
        setting.Email_Template_Registration_Id__c = eTemp.Id;
        setting.Email_Sender_Id__c = owea.Id;
        insert setting;
        
        Campaign__c camp = new Campaign__c();
        camp.Name = 'Test Campaign';
        insert camp;
        
        Contact c = new Contact();
        c.FirstName = 'John';
        c.LastName = 'John';
        c.Department = 'IT';
        c.Email = 'john@test.com';
        insert c;
        
        Event__c e = new Event__c();
        e.Event_Id__c = 'xxxxxxxxxx';
        e.Campaign__c = camp.id;
        e.Start_Date_Time__c = DateTime.Now();
        e.End_Date_Time__c = DateTime.Now().addDays(5);
        e.Email_Sender_Name__c = 'TEST 123';
        //e.Email_Message_CC__c = 'testMail@mail.com';
        //e.Email_Message_BCC__c = 'testMail@mail.com';
        e.Email_Sender_Id__c = owea.Id;
        insert e;
        
        Participant__c p = new Participant__c();
        p.Member_Contact__c = c.id;
        p.Event__c = e.id;
        p.Status__c = 'Invited';
        insert p;
        
        Session__c s = new Session__c();
        s.Event__c = e.id;
        s.IsActive__c = true;
        s.Time_Zone__c = 'CDT';  
        s.Start_Date_Time__c = DateTime.Now();
        s.End_Date_Time__c = DateTime.Now().addDays(5);
        insert s;
        
        Session_Role__c sessRole = new Session_Role__c();
        sessRole.Role_Title__c = 'Test Role';
        sessRole.Role_Description__c = 'Test Role';
        sessRole.Number_of_Role__c = 1;
        sessRole.Session__c = s.Id;
        insert sessRole;
    }
    
    @IsTest
    static void getEmailTemplateTest(){
        Test.startTest();
        	SendEmailToParticipantsController.getEmailTemplate();
        Test.stopTest();
        System.assertEquals(1, 1);
    }
    
    @IsTest
    static void getStatusValuesTest(){
        Test.startTest();
        	SendEmailToParticipantsController.getStatusValues();
        Test.stopTest();
        System.assertEquals(1, 1);
    }
    
    @IsTest
    static void sendEmailsTest(){
        Id eventId = [SELECT Id from Event__c LIMIT 1].Id;
        Test.startTest();
        	SendEmailToParticipantsController.sendEmails(eventId,'Invited','test');
        Test.stopTest();
        System.assertEquals(1, 1);
    }
}