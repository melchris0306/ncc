@isTest 
private class ChangeCloudControllerTest { 
    
    @testSetup
    static void makeTestData(){
        
        String inpputString = '2023-10-23T01:44:00.000Z';
        DateTime resultDateTime = DateTime.ValueofGmt(inpputString.replace('T', ' ')); 

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
        
        Apex_Trigger_Switch__c aps = new Apex_Trigger_Switch__c();
        aps.Name = 'EventTrigger';
        aps.Active__c = false;
        insert aps;
        
        
        Campaign__c camp = new Campaign__c();
        camp.Name = 'Test Campaign';
        insert camp;
        
        Account a = new Account();
        a.BillingStreet = 'Balston';
        a.BillingCity = 'Melbourne';
        a.BillingPostalCode = '3006';
        a.BillingState  = 'VIC';
        a.BillingCountry  = 'Australia';
        a.Name  = 'Imagine Marco';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'John';
        c.LastName = 'John';
        c.Department = 'IT';
        c.Email = 'John@test.com';
        insert c;
        
        Event__c e = new Event__c();
        e.Event_Id__c = 'xxxxxxxxxx';
        e.IsActive__c = true;
        e.Campaign__c = camp.id;
        e.Start_Date_Time__c = DateTime.Now();
        e.End_Date_Time__c = DateTime.Now() + 1;
        e.Location__c = a.Id;
        e.Email_Sender_Name__c = 'TEST 123';
        e.Email_Message_CC__c = 'testMail@mail.com';
        e.Email_Message_BCC__c = 'testMail@mail.com';
        e.Email_Sender_Id__c = owea.Id;
        e.Time_Zone__c = 'EDT';  // Added by JaysonLabnao [CCN-EVE-2160-DV] October102022
        insert e;
        
        Campaign campaignRecord = new Campaign();
        campaignRecord.Event_Id__c = 'kkjdu34302';
        campaignRecord.Name= 'Evendra123';
        campaignRecord.Subtitle__c= 'Evendra123';
        campaignRecord.Hero_Image_URL__c= 'https://www.google.com';
        campaignRecord.Campaign_Logo_URL__c= 'https://www.google.com';
        campaignRecord.Description__c= 'Evendra123';
        campaignRecord.Contact_Us_Tag_Line__c= 'Evendra123';
        campaignRecord.Contact_Us_Message__c= 'Evendra123';
        campaignRecord.Location__c = a.Id;
        campaignRecord.Start_Date_Time__c = DateTime.newInstance(2020, 08, 29, 22, 30, 0);
        campaignRecord.End_Date_Time__c = DateTime.newInstance(2020, 08, 30, 4, 50, 30);
        insert campaignRecord;
        
        Event_Role__c newEventRole = new Event_Role__c();
        newEventRole.Show_in_Event_Site__c = true;
        newEventRole.Role__c = 'Speaker';
        newEventRole.Contact__c = c.Id;
        newEventRole.Event__c = e.Id;
        newEventRole.Campaign__c = campaignRecord.Id ;
        insert newEventRole;
        
        Participant__c p = new Participant__c();
        p.Member_Contact__c = c.id;
        p.Event__c = e.id;
        insert p;
        
        Session__c s = new Session__c();
        s.Event__c = e.id;
        s.IsActive__c = true;
        s.Time_Zone__c = 'CDT';  
        s.Start_Date_Time__c = resultDateTime;
        s.End_Date_Time__c = resultDateTime.addHours(1);
        insert s;
        
        Session_Role__c sr = new Session_Role__c();
        sr.Role_Title__c = 'Sample Role';
        sr.Role_Description__c = 'Sample Description';
		sr.Session__c = s.Id;
        sr.Number_of_Role__c = 4;
        insert sr;
        
        Session_Participant__c sp = new Session_Participant__c();
        sp.Participant__c = p.Id;
        sp.Session__c = s.Id;
        insert sp;
        
        Lead l = new Lead();
        l.FirstName = 'Jane';
        l.LastName = 'Doe';
        l.Email = 'JaneDoe@test.com';
        l.Company = 'ABC Company';
        insert l;
        
        ContentVersion contentVersion = new ContentVersion(
            Title          = 'a picture',
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test Content'),
            IsMajorVersion = true);
        insert contentVersion;
        
        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId 
            FROM ContentDocument
        ];
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=e.id;
        contentlink.ShareType= 'V';
        contentlink.ContentDocumentId=documents[0].Id;
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        
        ContentDocumentLink contentlink2=new ContentDocumentLink();
        contentlink2.LinkedEntityId=s.id;
        contentlink2.ShareType= 'V';
        contentlink2.ContentDocumentId=documents[0].Id;
        contentlink2.Visibility = 'AllUsers'; 
        insert contentlink2;
        
        ContentDistribution cd = new ContentDistribution();
        cd.Name = 'Test';
        cd.ContentVersionId = contentVersion.id;
        cd.PreferencesAllowViewInBrowser= true;
        cd.PreferencesLinkLatestVersion=true;
        cd.PreferencesNotifyOnVisit=false;
        cd.PreferencesPasswordRequired=false;
        cd.PreferencesAllowOriginalDownload= true;
        insert cd;
        
    }
    
    @IsTest
    static void testInitTest() {
        CCEEventWrapper resultWrappers = new CCEEventWrapper();
        Participant__c p = [SELECT id,Name FROM Participant__c LIMIT 1];
        Test.startTest();
        Event__c event = [Select Event_Id__c from Event__c LIMIT 1];
        resultWrappers = ChangeCloudController.getEventDetails(event.Event_Id__c);
        Test.stopTest();
        System.assertNotEquals(resultWrappers, null);
    }    

    @IsTest
    static void testInit1Exception() {
        CCEEventWrapper resultWrappers = new CCEEventWrapper();
        Test.startTest();
        try{
            resultWrappers = ChangeCloudController.getEventDetails(null);            
        }catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
    }  
    
    @IsTest
    static void testInitTest2() {
        CCEEventWrapper resultWrappers = new CCEEventWrapper();
        Participant__c p = [SELECT id,Name FROM Participant__c LIMIT 1];
        Test.startTest();
        Event__c event = [Select Event_Id__c from Event__c LIMIT 1];
        resultWrappers = ChangeCloudController.getEventDetailsHeader(event.Event_Id__c,p.Name);
        Test.stopTest();
        System.assertNotEquals(resultWrappers, null);
    }    
    
    @IsTest
    static void testInit2Exception() {
        CCEEventWrapper resultWrappers = new CCEEventWrapper();
        Test.startTest();
        try{
            resultWrappers = ChangeCloudController.getEventDetailsHeader(null, null);            
        }catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
    } 
    
    
    @IsTest
    static void getEventSessionTest() {
        CCEEventWrapper resultWrappers = new CCEEventWrapper();
        Participant__c p = [SELECT id,Name FROM Participant__c LIMIT 1];
        Test.startTest();
        Event__c event = [Select Event_Id__c from Event__c LIMIT 1];
        resultWrappers = ChangeCloudController.getEventSession(event.Event_Id__c,p.Name,true);
        Test.stopTest();
        System.assertNotEquals(resultWrappers, null);
    } 

    @IsTest
    static void testgetEventSessionException() {
        CCEEventWrapper resultWrappers = new CCEEventWrapper();
        Test.startTest();
        try{
            resultWrappers = ChangeCloudController.getEventSession(null, null, null);            
        }catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
    }   
    
    @IsTest
    static void getEventSessionTest2() {
        CCEEventWrapper resultWrappers = new CCEEventWrapper();
        List<CCESpeakerWrapper> cceSpeaker = new List<CCESpeakerWrapper>(); 
        
        Participant__c p = [SELECT id,Name FROM Participant__c LIMIT 1];
        Test.startTest();
        Event__c event = [Select Event_Id__c from Event__c LIMIT 1];
        resultWrappers = ChangeCloudController.getEventSession(event.Event_Id__c,p.Name,false);
        cceSpeaker = ChangeCloudController.getSpeakerDetails(event.Event_Id__c);
        Test.stopTest();
        System.assertNotEquals(resultWrappers, null);
    }    
    
    @IsTest
    static void testgetEventMaterialst() {
        String result;
        Participant__c p = [SELECT id,Name FROM Participant__c LIMIT 1];
        Test.startTest();
        Event__c event = [Select Event_Id__c from Event__c LIMIT 1];
        result = ChangeCloudController.getEventMaterials(event.Event_Id__c);
        Test.stopTest();
    }    
    
    @IsTest
    static void getParticipantSessionTest() {
        List<compass_session_wrapper> resultWrappers = new List<compass_session_wrapper>();
        Participant__c p = [SELECT id,Name FROM Participant__c LIMIT 1];
        Test.startTest();
        resultWrappers = ChangeCloudController.getParticipantSession(p.Name);
        Test.stopTest();
        System.assertNotEquals(resultWrappers, null);
    }    
    
    @IsTest
    static void updateAttendanceTest() {
        Boolean resultWrappers;
        Session_Participant__c p = [SELECT id FROM Session_Participant__c LIMIT 1];
        Test.startTest();
        resultWrappers = ChangeCloudController.updateAttendance(p.Id);
        Test.stopTest();
        System.assertNotEquals(resultWrappers, null);
    }  
    
    @IsTest
    static void getParticipantByNumberTest() {
        Participant__c resultWrappers = new Participant__c();
        Participant__c p = [SELECT id,Name FROM Participant__c LIMIT 1];
        Test.startTest();
        resultWrappers = ChangeCloudController.getParticipantDetailByNumber(p.Name);
        Test.stopTest();
        System.assertNotEquals(resultWrappers, null);
    }    
    
    @IsTest
    static void getParticipantDetailTest() {
        Participant__c resultWrappers = new Participant__c();
        Test.startTest();
        resultWrappers = ChangeCloudController.getParticipantDetail('John@test.com','xxxxxxxxxx');
        Test.stopTest();
        System.assertNotEquals(resultWrappers, null);
    }    
    
    @IsTest
    static void createTaskTest() {
        Test.startTest();
        Event__c event = [Select Event_Id__c from Event__c LIMIT 1];
        ChangeCloudController.createTask(event.Event_Id__c, 'John', 'Test', 'John@test.com','021111111','Subject', 'Comment');
        Test.stopTest();
    }    
    
    @IsTest
    static void catchUpSessionTest() {
        Test.startTest();
        Boolean status;
        Session_Participant__c p = [SELECT id FROM Session_Participant__c LIMIT 1];
        Event__c event = [Select Event_Id__c from Event__c LIMIT 1];
        try{
           status = ChangeCloudController.catchUpSession(p.Id, event.Event_Id__c); 
        }
        catch (Exception e){
            System.assert(TRUE);
        }
        Test.stopTest();
    }    

    @IsTest
    static void getEventsListTest() {
        Test.startTest();
        Campaign camp = [Select Id From Campaign LIMIT 1];
        List<CCEEventWrapper> cceWrapper = new List<CCEEventWrapper>(); 
        List<String> eventTypes = new List<String>();
        List<String> eventNames = new List<String>();
        cceWrapper = ChangeCloudController.getEventsList(camp.Id, eventTypes, eventNames);
        eventTypes.add('Virtual'); 
        cceWrapper = ChangeCloudController.getEventsList(camp.Id, eventTypes, eventNames);
        eventNames.add('Evendra123'); 
        cceWrapper = ChangeCloudController.getEventsList(camp.Id, eventTypes, eventNames);
        eventTypes.clear();
        cceWrapper = ChangeCloudController.getEventsList(camp.Id, eventTypes, eventNames);
        Test.stopTest();
    }    

    @IsTest
    static void getSortedEventsListTest() {
        Test.startTest();
        Campaign camp = [Select Id From Campaign LIMIT 1];
        List<CCEEventWrapper> cceWrapper = new List<CCEEventWrapper>(); 
        List<String> eventTypes = new List<String>();
        List<String> eventNames = new List<String>();
        try{
            cceWrapper = ChangeCloudController.getSortedEventsList(camp.Id, 'ASC', eventTypes, eventNames); 
            eventTypes.add('Virtual'); 
            cceWrapper = ChangeCloudController.getSortedEventsList(camp.Id, 'ASC', eventTypes, eventNames);
            eventNames.add('Evendra123'); 
            cceWrapper = ChangeCloudController.getSortedEventsList(camp.Id, 'ASC', eventTypes, eventNames);
            eventTypes.clear();
            cceWrapper = ChangeCloudController.getSortedEventsList(camp.Id, 'ASC', eventTypes, eventNames);
        }
        catch (Exception e){
            system.debug(TRUE);
        }
        Test.stopTest();
    }  
    @IsTest
    static void getSessionDetailsTest() {
        Test.startTest();
        Session__c p = [SELECT id FROM Session__c LIMIT 1];
 		Session__c result = ChangeCloudController.getSessionDetails(p.Id); 	
        Test.stopTest();
    }   
    @IsTest
    static void getSessionRolesTest() {
        Test.startTest();
        Session__c p = [SELECT id FROM Session__c LIMIT 1];
 		List<Session_Role__c> result = ChangeCloudController.getSessionRoles(p.Id); 	
        Test.stopTest();
    }   
    @IsTest
    static void getSessionParticipantsTest() {
        Test.startTest();
        Session__c p = [SELECT id FROM Session__c LIMIT 1];
 		List<Session_Participant__c> result = ChangeCloudController.getSessionParticipants(p.Id); 	
        Test.stopTest();
    }   
    @IsTest
    static void setSessionParticipantsStatusTest() {
        Test.startTest();
        Session_Participant__c p = [SELECT id FROM Session_Participant__c LIMIT 1];
 		ChangeCloudController.setSessionParticipantsStatus(p.Id); 	
        Test.stopTest();
    }   
    @IsTest
    static void addSessionParticipantsTest() {
        Test.startTest();
        Event__c e = [SELECT id FROM Event__c LIMIT 1];
        Session__c s = [SELECT id FROM Session__c LIMIT 1];
		// Updated By JaysonLabnao [CCN-EVE-2160-DV] OCT092022, XEN REYES March 5, 2023 CCN-EVE-2631-DV
 		ChangeCloudController.addSessionParticipants('xxxxxxxxxx',s.id,'fname','lname','role','sample@sample.com', 'Mr.', 'Others','Test'); 	
        Test.stopTest();
    } 

    // Added By JaysonLabnao [CCN-EVE-2160-DV] OCT102022
    @IsTest
    static void getRankPicklistsTest() {
        Test.startTest();
 		List<ChangeCloudController.PicklistOption> options = ChangeCloudController.getRankPicklists(); 	
        Test.stopTest();

        System.assert(!options.isEmpty(), 'ChangeCloudController.getRankPicklists() should return picklist values.');
    } 
    
    //XEN REYES March 5, 2023 CCN-EVE-2631-DV
    @IsTest
    static void getRankAndRankGroupDependenciesTest() {
        Test.startTest();
            Map<Object,List<String>> options = ChangeCloudController.getRankAndRankGroupDependencies(); 	
        Test.stopTest();

        System.assert(!options.isEmpty(), 'ChangeCloudController.getRankAndRankGroupDependencies() should return picklist values.');
    } 
}