/**
* Created by angelorivera on 30/8/20.
* Modified by Jasmine Nguyen on 10/9/2020 to use Start_Date_Time__c and End_Date_Time__c fields
*/

@IsTest
private class CC_EventRegistrationClassTest {
    
    @testSetup
    static void makeTestData(){
        OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        
        EmailTemplate eTemp = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
        system.runAs( new User(Id = UserInfo.getUserId())){
            insert eTemp;
        }
        
        Apex_Trigger_Switch__c aps = new Apex_Trigger_Switch__c();
        aps.Name = 'EventTrigger';
        aps.Active__c = false;
        insert aps;

        Apex_Trigger_Switch__c st = new Apex_Trigger_Switch__c();
        st.Name = 'SessionTrigger';
        st.Active__c = true;
        insert st;
        
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
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        Campaign__c camp = new Campaign__c();
        camp.Name = 'Test Campaign';
        camp.Account__c = acc.Id;
        insert camp;
        
        Contact c = new Contact();
        c.FirstName = 'John';
        c.LastName = 'John';
        c.Department = 'IT';
        c.Site__c = 'Test1';
        c.Email = 'John@test.com';
        insert c;

        Contact c2 = new Contact();
        c2.FirstName = 'k';
        c2.LastName = 'buhay';
        c2.Department = 'IT';
        c.Site__c = 'Test1';
        c2.Email = 'kbuhay@ulapp.co';
        insert c2;
        
        Event__c e = new Event__c();
        e.Event_Id__c = 'xxxxxxxxxx';
        e.Campaign__c = camp.id;
        e.Start_Date_Time__c = DateTime.Now();
        e.End_Date_Time__c = DateTime.Now().addDays(1);
        e.Email_Sender_Name__c = 'TEST 123';
        e.Email_Message_CC__c = 'testMail@mail.com';
        e.Email_Message_BCC__c = 'testMail@mail.com';
        e.Email_Sender_Id__c = owea.Id;
        //CCN-907 XEN REYES 11032021
        e.Site_picklist_values__c = 'Test1,Test2,Test3';
        e.Time_Zone__c = 'CDT';
        insert e;
        
        Participant__c p = new Participant__c();
        p.Member_Contact__c = c.id;
        p.Event__c = e.id;
        insert p;
        
        Session__c s = new Session__c();
        s.Event__c = e.id;
        s.IsActive__c = true;
        s.Time_Zone__c = 'CDT'; 
        s.Start_Date_Time__c = DateTime.Now();
        s.End_Date_Time__c = DateTime.Now().addHours(2);
        insert s;
        
        Lead l = new Lead();
        l.FirstName = 'Jane';
        l.LastName = 'Doe';
        l.Email = 'JaneDoe@test.com';
        l.Company = 'Acme';
        insert l;
        
    }
    
    @IsTest
    static void testInit() {
        CC_EventRegistrationClass.resultWrapper resultWrappers = new CC_EventRegistrationClass.resultWrapper();
        
        Participant__c p = [SELECT id,Name FROM Participant__c LIMIT 1];
        Event__c e = [SELECT Event_Id__c FROM Event__c Limit 1];
        
        Test.startTest();
        resultWrappers = CC_EventRegistrationClass.DoInit(e.Event_Id__c,p.Name);
        Test.stopTest();
        
    }
    
    @IsTest
    static void getCampaignMemberStatusTest(){
        
        Participant__c p = [SELECT id,Name,Event__c,Member_Contact__c FROM Participant__c LIMIT 1];
        Test.startTest();
        String result  = CC_EventRegistrationClass.getCampaignMemberStatus(p.Member_Contact__c,p.Event__c);
        Test.stopTest();
        
    }
    
    @IsTest
    static void submitBookingTest(){
        
        
        Session__c s = [Select id FROM Session__c limit 1];
        Event__c e = [Select id,Event_Id__c FROM Event__c limit 1];
        
        List<String> sessionIdsc  = new List<String>();
        sessionIdsc.Add(s.Id);        
        
        Test.startTest();
        String result  = CC_EventRegistrationClass.submitBooking(e.Event_Id__c,
                                                                 '{"RegistrationField_FirstName-Contact|FirstName":"kyzer","RegistrationField_LastName-Contact|LastName":"buhay",' +
                                                                 '"RegistrationField_Email-Contact|Email":"kbuhay@ulapp.co","RegistrationField_Department-Contact|Department":"IT","RegistrationField_Site-Contact|Site__c":"Test1"}',
                                                                 sessionIdsc,'"RegistrationField_Title-Contact|Title":{"required":false,"active":false}"');
        Test.stopTest();
        
    }
    
    @IsTest
    static void submitBookingTest2(){
        
        
        Session__c s = [Select id FROM Session__c limit 1];
        Event__c e = [Select id,Event_Id__c FROM Event__c limit 1];
        
        List<String> sessionIdsc  = new List<String>();
        sessionIdsc.Add(s.Id);        
        
        Test.startTest();
        String result  = CC_EventRegistrationClass.submitBooking(e.Event_Id__c,
                                                                 '{"RegistrationField_FirstName-Contact|FirstName":"kyzer","RegistrationField_LastName-Contact|LastName":"buhay",' +
                                                                 '"RegistrationField_Email-Contact|Email":"kbuhay@ulapp.co","RegistrationField_Department-Contact|Department":"IT","RegistrationField_Site-Contact|Site__c":"Test1"}',
                                                                 sessionIdsc,'"RegistrationField_Title-Contact|Title":{"required":false,"active":false}"');
        Test.stopTest();
        
    }    
    
    @IsTest
    static void submitBookingTest3(){
        
        
        Session__c s = [Select id FROM Session__c limit 1];
        Event__c e = [Select id,Event_Id__c FROM Event__c limit 1];
        
        List<String> sessionIdsc  = new List<String>();
        sessionIdsc.Add(s.Id);        
        
        Test.startTest();
        String result  = CC_EventRegistrationClass.submitBooking(e.Event_Id__c,
                                                                 '{"RegistrationField_FirstName-Contact|FirstName":"kyzer","RegistrationField_LastName-Contact|LastName":"buhay",' +
                                                                 '"RegistrationField_Email-Contact|Email":"kbuhay@ulapp.co","RegistrationField_Department-Contact|Department":"IT","RegistrationField_Site-Contact|Site__c":"Test1"}',
                                                                 sessionIdsc,'"RegistrationField_Title-Contact|Title":{"required":false,"active":false}"');
        Test.stopTest();
        
    }   

    @IsTest
    static void submitBookingTest4(){
        
        
        Session__c s = [Select id FROM Session__c limit 1];
        Event__c e = [Select id,Event_Id__c FROM Event__c limit 1];
        
        List<String> sessionIdsc  = new List<String>();
        sessionIdsc.Add(s.Id);        
        
        Test.startTest();
        String result  = CC_EventRegistrationClass.submitBooking(e.Event_Id__c,
                                                                 '{"RegistrationField_FirstName-Contact|FirstName":"no","RegistrationField_LastName-Contact|LastName":"contacttest",' +
                                                                 '"RegistrationField_Email-Contact|Email":"nocontacttest@ulapp.co","RegistrationField_Department-Contact|Department":"IT","RegistrationField_Site-Contact|Site__c":"Test1"}',
                                                                 sessionIdsc,'"RegistrationField_Title-Contact|Title":{"required":false,"active":false}"');
        Test.stopTest();
        
    }   

    @IsTest
    static void computeTimeZoneDiffTest(){
        
        Datetime testDateTime = DateTime.newInstance(2022, 6, 12, 0, 30, 0);
        Test.startTest();
        Datetime outputDate = CC_EventRegistrationClass.computeTimeZoneDiff(testDateTime, 'Asia/Manila');
        Test.stopTest();
        
        String outDate = outputDate.format('MMMM d, yyyy', 'Asia/Manila');

        System.assertEquals('June 12, 2022', outDate, 'Expected Date in text not equal to the actual output date.');

    }

    /* @IsTest
    static void generateMapByStringFieldTest(){
        
        List<Lead> leadList = [SELECT Id, LastName FROM Lead];
        Test.startTest();
        Map<String, sObject> resultMap  = CC_EventRegistrationClass.generateMapByStringField(leadList, 'LastName');
        Test.stopTest();
        
        Lead expectedLead = [SELECT Id, LastName FROM Lead WHERE Lastname = 'Doe'];
        System.assertEquals(expectedLead.Id, resultMap.get('Doe').Id);
    } */
    
    
    
}