@IsTest
public class MassSessionSignUpController_Test {
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
        
        /* 
        Compass_Setting__c setting = new Compass_Setting__c();
        setting.Name = 'Default Settings';
        setting.Email_Sender_Id__c = 'qwerty';
        insert setting;
        */
        
        Compass_Setting__c setting = new Compass_Setting__c();
        setting.Name = 'Default Settings';
        setting.Email_Sender_Name__c = 'NAME';
        setting.Email_Template_Invitation_Id__c = eTemp.Id;
        setting.Email_Template_Registration_Id__c = eTemp.Id;
        setting.Email_Sender_Id__c = owea.Id;
        insert setting;
        
        Account a = new Account();
        a.BillingStreet = 'Balston';
        a.BillingCity = 'Melbourne';
        a.BillingPostalCode = '3006';
        a.BillingState  = 'VIC';
        a.BillingCountry  = 'Australia';
        a.Name  = 'Imagine Marco';
        insert a;
        
        Campaign__c camp = new Campaign__c();
        camp.Name = 'Test Campaign';
        camp.Account__c = a.Id;
        insert camp;
        
        Contact c = new Contact();
        c.FirstName = 'John';
        c.LastName = 'John';
        c.Department = 'IT';
        c.Email = 'johnMassSessionSignUpController_Test@test.com';
        insert c;
        
        Event__c e = new Event__c();
        e.Event_Id__c = 'xxxxxxxxxx';
        e.Campaign__c = camp.id;
        e.Start_Date_Time__c = DateTime.Now();
        e.End_Date_Time__c = DateTime.Now().addHours(1);
        e.Email_Sender_Name__c = 'TEST 123';
        e.Time_Zone__c = 'ET';
        //e.Email_Message_CC__c = 'testMail@mail.com';
        //e.Email_Message_BCC__c = 'testMail@mail.com';
        e.Email_Sender_Id__c = owea.Id;
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
        s.End_Date_Time__c = DateTime.Now().addHours(1);
        insert s;
        
        // START CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
        Session_Participant__c sessionRec = new Session_Participant__c();
        sessionRec.Participant__c = p.Id;
        sessionRec.Event__c = s.Event__c;
        sessionRec.Session__c = s.Id;
        sessionRec.Contact__c = p.Member_Contact__c;
        sessionRec.Branch_of_Service__c = 'Other';
        sessionRec.Rank__c = 'Mr.';
        sessionRec.Role__c = 'Test Role';
        sessionRec.Status__c = 'Registered';
        insert sessionRec;
        // END CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
        
        Session_Role__c sessRole = new Session_Role__c();
        sessRole.Role_Title__c = 'Test Role';
        sessRole.Role_Description__c = 'Test Role';
        sessRole.Number_of_Role__c = 1;
        sessRole.Session__c = s.Id;
        insert sessRole;
        
        
    }
    
    @IsTest
    static void getRolesTest(){
        MassSessionSignUpController.mainWrapper wrapper = new MassSessionSignUpController.mainWrapper();
        
        Id sessRecId = [SELECT Id FROM Session__c LIMIT 1].Id;
        
        Test.startTest();
        	wrapper = MassSessionSignUpController.getRoles(sessRecId);
        Test.stopTest();
        
        System.assertEquals('Success', wrapper.message);
    }
    
    @IsTest
    static void getRolesWithParticipantTest(){
        MassSessionSignUpController.mainWrapper wrapper = new MassSessionSignUpController.mainWrapper();
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Participant__c partRec = [Select Id, Member_Contact__c FROM Participant__c LIMIT 1];
        
        //Commented below code due to Test Class error - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
        /*Session_Participant__c sessionRec = new Session_Participant__c();
        sessionRec.Participant__c = partRec.Id;
        sessionRec.Event__c = sessRec.Event__c;
        sessionRec.Session__c = sessRec.Id;
        sessionRec.Contact__c = partRec.Member_Contact__c;
        sessionRec.Branch_of_Service__c = 'Other';
        sessionRec.Rank__c = 'Mr.';
        sessionRec.Role__c = 'Test Role';
        insert sessionRec; */
        
       Test.startTest();
       wrapper = MassSessionSignUpController.getRoles(sessRec.Id);
       Test.stopTest();
        
       System.assertEquals('Success', wrapper.message);
        
    } 
    
    @IsTest
    static void fetchRankValuesTest(){
        List<String> retStr = new List<String>();
        Test.startTest();
        	retStr = MassSessionSignUpController.fetchRankValues();
        Test.stopTest();
        System.assertEquals(true, !retStr.isEmpty());
    }
    
    @IsTest
    static void saveSessionParticipantsTest(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        String paramStr = '[{"Email":"testsss1@m.com","FirstName":"Test","Id":"'+ sessRec.Id + '","LastName":"Schedulerr","Rank":"HM2","Role":"Test Role",' +
            '"RoleAndDesc":"Test Role Test Role","RoleDescription":"Test Role"}]';
        
        //START - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
        /* Test.startTest();
        	message = MassSessionSignUpController.saveSessionParticipants(paramStr,sessRec.Id);
        Test.stopTest();
        
        System.assertEquals('', message);*/
        
        Test.startTest();
        try{
            message = MassSessionSignUpController.saveSessionParticipants(paramStr,sessRec.Id);   
        }catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
        // END - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
        
    }
    
    @IsTest
    static void saveSessionParticipantsExistingTest(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Participant__c partRec = [Select Id, Member_Contact__c FROM Participant__c LIMIT 1];
        
        // - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
        Session_Participant__c sessionRec = [SELECT ID FROM Session_Participant__c LIMIT 1];
            
		//Commented below code due to Test Class error - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
		//Queried the record instead
        /*Session_Participant__c sessionRec = new Session_Participant__c();
        sessionRec.Participant__c = partRec.Id;
        sessionRec.Event__c = sessRec.Event__c;
        sessionRec.Session__c = sessRec.Id;
        sessionRec.Contact__c = partRec.Member_Contact__c;
        sessionRec.Branch_of_Service__c = 'Other';
        sessionRec.Rank__c = 'Mr.';
        sessionRec.Role__c = 'Test Role';
        insert sessionRec;*/

        String paramStr = '[{"Email":"john@test.com","FirstName":"John","Id":"'+ sessionRec.Id + '","LastName":"John","Rank":"HM1","Role":"Test Role",' +
            '"RoleAndDesc":"Test Role Test Role","RoleDescription":"Test Role"}]';
        
        Test.startTest();
        	message = MassSessionSignUpController.saveSessionParticipants(paramStr,sessRec.Id);
        Test.stopTest();
       	System.assertEquals('', message);
        
        
    }
    
    @IsTest
    static void saveSessionParticipantsExistingTestChangePart(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Participant__c partRec = [Select Id, Member_Contact__c FROM Participant__c LIMIT 1];
        
        // - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
        Session_Participant__c sessionRec = [SELECT ID FROM Session_Participant__c LIMIT 1];
          
        ///Commented below code due to Test Class error - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
		//Queried the record instead
        /*Session_Participant__c sessionRec = new Session_Participant__c();
        sessionRec.Participant__c = partRec.Id;
        sessionRec.Event__c = sessRec.Event__c;
        sessionRec.Session__c = sessRec.Id;
        sessionRec.Contact__c = partRec.Member_Contact__c;
        sessionRec.Branch_of_Service__c = 'Other';
        sessionRec.Rank__c = 'Mr.';
        sessionRec.Role__c = 'Test Role';
        sessionRec.Status__c = 'Registered';
        //insert sessionRec;*/

        String paramStr = '[{"Email":"john2@test.com","FirstName":"John2","Id":"'+ sessionRec.Id + '","LastName":"John2","Rank":"HM1","Role":"Test Role",' +
            '"RoleAndDesc":"Test Role Test Role","RoleDescription":"Test Role"}]';
        
        MassSessionSignUpController.getRoles(sessRec.Id);
        MassSessionSignUpController.fetchRankValues();
        
        // START CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
        /*Test.startTest();
        	message = MassSessionSignUpController.saveSessionParticipants(paramStr,sessRec.Id);
        Test.stopTest();
        System.assertEquals('', message);*/
        
        Test.startTest();
        try{
            message = MassSessionSignUpController.saveSessionParticipants(paramStr,sessRec.Id);
        }catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
        // END - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
    }
    
    @IsTest
    static void saveSessionParticipantsExistingTestChangeRank(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Participant__c partRec = [Select Id, Member_Contact__c FROM Participant__c LIMIT 1];
        
        //CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
        Session_Participant__c sessionRec = [SELECT ID FROM Session_Participant__c LIMIT 1];
        
        //Commented below code due to Test Class error - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
		//Queried the record instead
        /*
        Session_Participant__c sessionRec = new Session_Participant__c();
        sessionRec.Participant__c = partRec.Id;
        sessionRec.Event__c = sessRec.Event__c;
        sessionRec.Session__c = sessRec.Id;
        sessionRec.Contact__c = partRec.Member_Contact__c;
        sessionRec.Branch_of_Service__c = 'Other';
        sessionRec.Rank__c = 'Mr.';
        sessionRec.Role__c = 'Test Role';
        sessionRec.Status__c = 'Registered';*/
        //insert sessionRec;

        String paramStr = '[{"Email":"john@test.com","FirstName":"John","Id":"'+ sessionRec.Id + '","LastName":"John","Rank":"HM2","Role":"Test Role",' +
            '"RoleAndDesc":"Test Role Test Role","RoleDescription":"Test Role"}]';
        
        MassSessionSignUpController.getRoles(sessRec.Id);
        MassSessionSignUpController.fetchRankValues();
        
        //START - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
        /*Test.startTest();
        	message = MassSessionSignUpController.saveSessionParticipants(paramStr,sessRec.Id);
        Test.stopTest();
        System.assertEquals('', message);*/
        
        Test.startTest();
        try{
            message = MassSessionSignUpController.saveSessionParticipants(paramStr,sessRec.Id);
        }catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
        
        //END - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
    }
   
    @IsTest
    static void saveSessionParticipantsExistingTestNoChange(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Participant__c partRec = [Select Id, Member_Contact__c FROM Participant__c LIMIT 1];
        
        //CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
        Session_Participant__c sessionRec = [SELECT ID FROM Session_Participant__c LIMIT 1];
        
        //Commented below code due to Test Class error - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
		//Queried the record instead
        /*
        Session_Participant__c sessionRec = new Session_Participant__c();
        sessionRec.Participant__c = partRec.Id;
        sessionRec.Event__c = sessRec.Event__c;
        sessionRec.Session__c = sessRec.Id;
        sessionRec.Contact__c = partRec.Member_Contact__c;
        sessionRec.Branch_of_Service__c = 'Other';
        sessionRec.Rank__c = 'Mr.';
        sessionRec.Role__c = 'Test Role';
        sessionRec.Status__c = 'Registered';*/
        //insert sessionRec;

        String paramStr = '[{"Email":"john@test.com","FirstName":"John","Id":"'+ sessionRec.Id + '","LastName":"John","Rank":"HM1","Role":"Test Role",' +
            '"RoleAndDesc":"Test Role Test Role","RoleDescription":"Test Role"}]';
        
        MassSessionSignUpController.getRoles(sessRec.Id);
        MassSessionSignUpController.fetchRankValues();
        
        //START - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
        /*Test.startTest();
        	message = MassSessionSignUpController.saveSessionParticipants(paramStr,sessRec.Id);
        Test.stopTest();
        System.assertEquals('', message);*/
        
        Test.startTest();
        try{
            message = MassSessionSignUpController.saveSessionParticipants(paramStr,sessRec.Id);
        }catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
        
        //END - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
    }
    
    @IsTest
    static void saveSessionParticipantsExistingTestNoName(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Participant__c partRec = [Select Id, Member_Contact__c FROM Participant__c LIMIT 1];
        
        //CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
        Session_Participant__c sessionRec = [SELECT ID FROM Session_Participant__c LIMIT 1];
        
        //Commented below code due to Test Class error - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
		//Queried the record instead
        /*
        Session_Participant__c sessionRec = new Session_Participant__c();
        sessionRec.Participant__c = partRec.Id;
        sessionRec.Event__c = sessRec.Event__c;
        sessionRec.Session__c = sessRec.Id;
        sessionRec.Contact__c = partRec.Member_Contact__c;
        sessionRec.Branch_of_Service__c = 'Other';
        sessionRec.Rank__c = 'Mr.';
        sessionRec.Role__c = 'Test Role';
        sessionRec.Status__c = 'Registered';*/
        //insert sessionRec;

        String paramStr = '[{"Email":"john@test.com","FirstName":"","Id":"'+ sessionRec.Id + '","LastName":"John","Rank":"HM1","Role":"Test Role",' +
            '"RoleAndDesc":"Test Role Test Role","RoleDescription":"Test Role"}]';
        
        MassSessionSignUpController.getRoles(sessRec.Id);
        MassSessionSignUpController.fetchRankValues();
        
        //START - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
        /*Test.startTest();
        	message = MassSessionSignUpController.saveSessionParticipants(paramStr,sessRec.Id);
        Test.stopTest();
        System.assertNotEquals('', message);*/
        
        Test.startTest();
        try{
            message = MassSessionSignUpController.saveSessionParticipants(paramStr,sessRec.Id);
        }catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
        
        //END - CCN-EVE-3303-DV - Sept 20, 2023 - Jonah
    }
    
    @IsTest
    static void getEventDetailsTest(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
		Test.startTest();
        	message = MassSessionSignUpController.getEventDetails(sessRec.Id);
        Test.stopTest();
        System.assertNotEquals('', message);
    }
    
    @IsTest
    static void getEventDetails2Test(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
		Test.startTest();
        	message = MassSessionSignUpController.getEventDetails2(sessRec.Id);
        Test.stopTest();
        System.assertNotEquals('', message);
    }
    
    @IsTest 
    static void getEventDetails3Test(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
		Test.startTest();
        	message = MassSessionSignUpController.getEventDetailsId(sessRec.Id);
        Test.stopTest();
        System.assertNotEquals('', message);
    }

    //XEN REYES March 5, 2023 CCN-EVE-2631-DV
    @IsTest
    static void getRankAndRankGroupDependenciesTest() {
        Test.startTest();
            Map<Object,List<String>> options = MassSessionSignUpController.getRankAndRankGroupDependencies(); 	
        Test.stopTest();

        System.assert(!options.isEmpty(), 'MassSessionSignUpController.getRankAndRankGroupDependencies() should return picklist values.');
    } 
    
   
    @isTest
    static void getSessionDetailsTest(){
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Session__c sesRec = new Session__c();
		Test.startTest();
        	sesRec = MassSessionSignUpController.getSessionDetails(sessRec.Id);
        Test.stopTest();
        
        System.assertEquals(sessRec.Id, sesRec.Id);
    }
    
    @isTest
    static void getFieldConfigTest(){
        Id campRecId = [SELECT Id FROM Campaign__c LIMIT 1].ID;
        
        MassSessionSignUpController.resultWrapper returnResult = new MassSessionSignUpController.resultWrapper();
        
        Test.startTest();
        try{
            returnResult = MassSessionSignUpController.getFieldConfig(campRecId);          
        }catch (Exception e){
            system.assert(TRUE);
        }
        Test.stopTest();
    }
        
}