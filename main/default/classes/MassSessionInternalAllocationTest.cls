@IsTest
public class MassSessionInternalAllocationTest {
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
        
        Compass_Setting__c setting = new Compass_Setting__c();
        setting.Name = 'Default Settings';
        setting.Email_Sender_Name__c = 'NAME';
        setting.Email_Template_Invitation_Id__c = eTemp.Id;
        setting.Email_Template_Registration_Id__c = eTemp.Id;
        setting.Email_Sender_Id__c = owea.Id;
        insert setting;
          
        Account ac = new Account(name ='Ulapp');
        insert ac; 

        Campaign__c camp = new Campaign__c();
        camp.Account__c = ac.Id;
        camp.Name = 'Test Campaign';
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
        e.Email_Sender_Id__c = owea.Id;
        insert e;
        
        Internal_Resource__c p = new Internal_Resource__c();
        p.Contact__c = c.id;
        p.Event__c = e.id;
        insert p;
        
        Session__c s = new Session__c();
        s.Event__c = e.id;
        s.IsActive__c = true;
        s.Time_Zone__c = 'CDT';  
        s.Start_Date_Time__c = DateTime.Now();
        s.End_Date_Time__c = DateTime.Now().addHours(1);
        insert s;
        
        Internal_Resource_Role__c intRole = new Internal_Resource_Role__c();
        intRole.Internal_Resource_Role_Title__c = 'Test Role';
        intRole.Internal_Resource_Role_Description__c = 'Test Role';
        intRole.Internal_Resource_Number_of_Role__c = 1;
        intRole.Session__c = s.Id;
        insert intRole;
    }
    
    @IsTest
    static void getRolesTest(){
        MassSessionInternalAllocationController.mainWrapper wrapper = new MassSessionInternalAllocationController.mainWrapper();
        
        Id sessRecId = [SELECT Id FROM Session__c LIMIT 1].Id;
        
        Test.startTest();
            wrapper = MassSessionInternalAllocationController.getRoles(sessRecId);
        Test.stopTest();
        
        System.assertEquals('Success', wrapper.message);
    }
    
    @IsTest
    static void getRolesWithParticipantTest(){
        MassSessionInternalAllocationController.mainWrapper wrapper = new MassSessionInternalAllocationController.mainWrapper();
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Internal_Resource__c ir = [Select Id, Contact__c FROM Internal_Resource__c LIMIT 1];
        
        Internal_Resource_Session__c irs = new Internal_Resource_Session__c();
        irs.Resource__c = ir.Id;
        irs.Event__c = sessRec.Event__c;
        irs.Session__c = sessRec.Id;
        irs.Contact__c = ir.Contact__c;
        insert irs;
        
        Test.startTest();
            wrapper = MassSessionInternalAllocationController.getRoles(sessRec.Id);
        Test.stopTest();
        
        System.assertEquals('Success', wrapper.message);
    }

    
    @IsTest
    static void saveInternalResourceSessionTest(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        String paramStr = '[{"Email":"testsss1@m.com","FirstName":"Test","Id":"'+ sessRec.Id + '","LastName":"Schedulerr","Role":"Test Role",' +
            '"RoleAndDesc":"Test Role Test Role","RoleDescription":"Test Role"}]';
        
        Test.startTest();
            message = MassSessionInternalAllocationController.saveSessionInternalResource(paramStr,sessRec.Id);
        Test.stopTest();
        
        System.assertEquals('', message);
    }
    
    @IsTest
    static void saveInternalResourceSessionExistingTest(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Internal_Resource__c ir = [Select Id, Contact__c FROM Internal_Resource__c LIMIT 1];
        
        Internal_Resource_Session__c irs = new Internal_Resource_Session__c();
        irs.Resource__c = ir.Id;
        irs.Event__c = sessRec.Event__c;
        irs.Session__c = sessRec.Id;
        irs.Contact__c = ir.Contact__c;
        irs.Resource_Session_Role__c = 'Test Role';
        insert irs;

        String paramStr = '[{"Email":"john@test.com","FirstName":"John","Id":"'+ sessRec.Id + '","LastName":"John","Role":"Test Role",' +
            '"RoleAndDesc":"Test Role Test Role","RoleDescription":"Test Role"}]';
        
        Test.startTest();
            message = MassSessionInternalAllocationController.saveSessionInternalResource(paramStr,sessRec.Id);
        Test.stopTest();
        System.assertEquals('', message);
    }
    
    @IsTest
    static void saveInternalResourceSessionExistingTestChangePart(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Internal_Resource__c ir = [Select Id, Contact__c FROM Internal_Resource__c LIMIT 1];
        
        Internal_Resource_Session__c irs = new Internal_Resource_Session__c();
        irs.Resource__c  = ir.Id;
        irs.Event__c = sessRec.Event__c;
        irs.Session__c = sessRec.Id;
        irs.Contact__c = ir.Contact__c;
        irs.Resource_Session_Role__c = 'Test Role';
        irs.Resource_Session_Status__c = 'Registered';
        insert irs;

        String paramStr = '[{"Email":"john2@test.com","FirstName":"John2","Id":"'+ sessRec.Id + '","LastName":"John2","Role":"Test Role",' +
            '"RoleAndDesc":"Test Role Test Role","RoleDescription":"Test Role"}]';
        
        MassSessionInternalAllocationController.getRoles(sessRec.Id);
        
        Test.startTest();
            message = MassSessionInternalAllocationController.saveSessionInternalResource(paramStr,sessRec.Id);
        Test.stopTest();
        System.assertEquals('', message);
    }
    
   
   
   
    @IsTest
    static void saveInternalResourceSessionExistingTestNoChange(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Internal_Resource__c ir = [Select Id, Contact__c FROM Internal_Resource__c LIMIT 1];
        
        Internal_Resource_Session__c irs = new Internal_Resource_Session__c();
        irs.Resource__c  = ir.Id;
        irs.Event__c = sessRec.Event__c;
        irs.Session__c = sessRec.Id;
        irs.Contact__c = ir.Contact__c;
        irs.Resource_Session_Role__c = 'Test Role';
        irs.Resource_Session_Status__c = 'Registered';
        insert irs;

        String paramStr = '[{"Email":"john@test.com","FirstName":"John","Id":"'+ sessRec.Id + '","LastName":"John","Role":"Test Role",' +
            '"RoleAndDesc":"Test Role Test Role","RoleDescription":"Test Role"}]';
        
        MassSessionInternalAllocationController.getRoles(sessRec.Id);
        
        Test.startTest();
            message = MassSessionInternalAllocationController.saveSessionInternalResource(paramStr,sessRec.Id);
        Test.stopTest();
        System.assertEquals('', message);
    }
     @IsTest
    static void removeRole(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Internal_Resource__c ir = [Select Id, Contact__c FROM Internal_Resource__c LIMIT 1];
        
        Internal_Resource_Session__c irs = new Internal_Resource_Session__c();
        irs.Resource__c  = ir.Id;
        irs.Event__c = sessRec.Event__c;
        irs.Session__c = sessRec.Id;
        irs.Contact__c = ir.Contact__c;
        irs.Resource_Session_Role__c = 'Test Role';
        irs.Resource_Session_Status__c = 'Registered';
        insert irs;

        String paramStr = '[{"Email":"","FirstName":"","Id":"'+ sessRec.Id + '","LastName":"","Role":"Test Role",' +
            '"RoleAndDesc":"Test Role Test Role","RoleDescription":"Test Role"}]';
        
        MassSessionInternalAllocationController.getRoles(sessRec.Id);
        
        Test.startTest();
            message = MassSessionInternalAllocationController.saveSessionInternalResource(paramStr,sessRec.Id);
            MassSessionInternalAllocationController.removeRole(irs.Id);
        Test.stopTest();
    }
  
    @IsTest
    static void saveInternalResourceSessionExistingTestNoName(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Internal_Resource__c ir = [Select Id, Contact__c FROM Internal_Resource__c LIMIT 1];
        
        Internal_Resource_Session__c irs = new Internal_Resource_Session__c();
        irs.Resource__c  = ir.Id;
        irs.Event__c = sessRec.Event__c;
        irs.Session__c = sessRec.Id;
        irs.Contact__c = ir.Contact__c;
        irs.Resource_Session_Role__c = 'Test Role';
        irs.Resource_Session_Status__c = 'Registered';
        insert irs;

        String paramStr = '[{"Email":"john@test.com","FirstName":"","Id":"'+ sessRec.Id + '","LastName":"John","Role":"Test Role",' +
            '"RoleAndDesc":"Test Role Test Role","RoleDescription":"Test Role"}]';
        
        MassSessionInternalAllocationController.getRoles(sessRec.Id);
        
        Test.startTest();
            message = MassSessionInternalAllocationController.saveSessionInternalResource(paramStr,sessRec.Id);
        Test.stopTest();
        System.assertNotEquals('', message);
    }
    
    @IsTest
    static void getEventDetailsTest(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Test.startTest();
            message = MassSessionInternalAllocationController.getEventDetails(sessRec.Id);
        Test.stopTest();
        System.assertNotEquals('', message);
    }
    
    @IsTest
    static void getEventDetails2Test(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Test.startTest();
            message = MassSessionInternalAllocationController.getEventDetails2(sessRec.Id);
        Test.stopTest();
        System.assertNotEquals('', message);
    }
    
    @IsTest 
    static void getEventDetails3Test(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Test.startTest();
            message = MassSessionInternalAllocationController.getEventDetailsId(sessRec.Id);
        Test.stopTest();
        System.assertNotEquals('', message);
    }
    @IsTest
    static void getSessionDetailsTest(){
        String message = '';
        Session__c sessRec = [SELECT Id,Event__c FROM Session__c LIMIT 1];
        Test.startTest();
            Session__c s = MassSessionInternalAllocationController.getSessionDetails(sessRec.Id);
        Test.stopTest();
        System.assertNotEquals(null, s);
    }
}