@IsTest
public class SignedUpRolesSummaryController_Test {
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
        
        Contact c2 = new Contact();
        c2.FirstName = 'John2';
        c2.LastName = 'John2';
        c2.Department = 'IT2';
        c2.Email = 'john2@test.com';
        insert c2;
        
        Event__c e = new Event__c();
        e.Event_Id__c = 'xxxxxxxxxx';
        e.Campaign__c = camp.id;
        e.Start_Date_Time__c = DateTime.Now();
        e.End_Date_Time__c = DateTime.Now()+1;
        e.Email_Sender_Name__c = 'TEST 123';
        //e.Email_Message_CC__c = 'testMail@mail.com';
        //e.Email_Message_BCC__c = 'testMail@mail.com';
        e.Email_Sender_Id__c = owea.Id;
        insert e;
        
        Participant__c p = new Participant__c();
        p.Member_Contact__c = c.id;
        p.Event__c = e.id;
        insert p;
        
        Participant__c p2 = new Participant__c();
        p2.Member_Contact__c = c2.id;
        p2.Event__c = e.id;
        insert p2;
        
        Session__c s = new Session__c();
        s.Event__c = e.id;
        s.IsActive__c = true;
        s.Time_Zone__c = 'EDT';  
        s.Start_Date_Time__c = DateTime.Now();
        s.End_Date_Time__c = DateTime.Now()+1;
        insert s;
        
        Session_Role__c sessRole = new Session_Role__c();
        sessRole.Role_Title__c = 'Test Role';
        sessRole.Role_Description__c = 'Test Role';
        sessRole.Number_of_Role__c = 1;
        sessRole.Session__c = s.Id;
        insert sessRole;
        
        Session_Participant__c sessionRec = new Session_Participant__c();
        sessionRec.Participant__c = p.Id;
        sessionRec.Event__c = e.id;
        sessionRec.Session__c = s.Id;
        sessionRec.Contact__c = c.Id;
        //sessionRec.Rank__c = 'COL';
        sessionRec.Role__c = 'Test Role';
        insert sessionRec;
        
        Session_Participant__c sessionRec2 = new Session_Participant__c();
        sessionRec2.Participant__c = p2.Id;
        sessionRec2.Event__c = e.id;
        sessionRec2.Session__c = s.Id;
        sessionRec2.Contact__c = c2.Id;
        //sessionRec2.Rank__c = 'COL';
        sessionRec2.Role__c = 'Test Role';
        sessionRec2.Status__c = 'Canceled';
        insert sessionRec2;
    }
    
    @IsTest
    static void getRecordsTest(){
        SignedUpRolesSummaryController.mainWrapper wrapper = new SignedUpRolesSummaryController.mainWrapper();
        
        Id eventRecId = [SELECT Id FROM Event__c LIMIT 1].Id;
        
        Test.startTest();
        	wrapper = SignedUpRolesSummaryController.getRecords(eventRecId);
        Test.stopTest();
        
        System.assertEquals('Success', wrapper.message);
    }
}