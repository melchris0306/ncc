@IsTest
public class CaseTriggerHandler_Test {
	@TestSetup
    static void createData(){
        User ceoUser = [SELECT Id, UserRole.DeveloperName FROM User WHERE UserRole.DeveloperName='CEO' AND isActive = True LIMIT 1];
        System.runAs ( ceoUser ) {
            Profile compassAgilePMUserId = [SELECT Id FROM Profile WHERE Name = 'Compass Agile PM User'];
            //UserRole r = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'UlappCustomerUser' LIMIT 1];
            system.debug('profid:' + compassAgilePMUserId);
            Account ac = new Account(name ='Ulapp');
            insert ac; 
           
            Contact con = new Contact(LastName ='testCon',AccountId = ac.Id, Email='test1@com.com');
            insert con;  
                      
            User user = new User(alias = 'test123', email='test123@noemail.com',
                    emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                    localesidkey='en_US', country='United States',IsActive =true,
                    ContactId = con.Id, PortalRole='Manager',
                    timezonesidkey='America/Los_Angeles', username='tester@noemail.com', profileid = compassAgilePMUserId.Id);
            System.debug('userbeforecreate:'  + user);
            //insert user;
            
            //PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Compass_Agile_Project_Collaborator_Access'];
            //insert new PermissionSetAssignment(AssigneeId = user.id, PermissionSetId = ps.Id);
        }
        
        Id accCustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        Account customerAccount = new Account();
        customerAccount.Name = 'Test Account #1';
        customerAccount.RecordTypeId = accCustomerRecordTypeId;
        insert customerAccount;
        
        Project__c projRecord = new Project__c();
        projRecord.Project_Code__c = 'CCN';
        projRecord.Name = 'Test Project #A';
        projRecord.Account__c = customerAccount.Id;
        projRecord.Starting_Task_Number__c = 0;
        projRecord.Task_Number_Display_Format__c = '{mm}';
        projRecord.Do_Not_Require_Sprint__c = True;
        
        insert projRecord;
    }
    
    @IsTest
    static void createProjectTaskViaCase(){
        Id compassRecTypeId = [Select Id from RecordType WHERE Name = 'Compass'].Id;
      	Case csRec = new Case();
        List<Case> newCaseList = new List<Case>();
        csRec.Status = 'New';
        csRec.Type = 'New feature';
        csRec.Application__c = 'CCN';
        csRec.RecordTypeId = compassRecTypeId;
        newCaseList.add(csRec);
        insert newCaseList;
        Test.startTest();
        	csRec.Create_Project_Task__c = true;	
        	update csRec;
        Test.stopTest();
    }
    
    @IsTest
    static void captureErrorMsgTest(){
        Id compassRecTypeId = [Select Id from RecordType WHERE Name = 'Compass'].Id;
        Case csRec = new Case();
        List<Case> newCaseList = new List<Case>();
        csRec.Status = 'New';
        csRec.Type = 'New feature';
        csRec.Application__c = 'CCN';
        csRec.RecordTypeId = compassRecTypeId;
        newCaseList.add(csRec);
        insert newCaseList;
        
        Map<Id, Case> caseMap = new Map<Id, Case>();
        caseMap.put(csRec.Id, csRec);
        
        Test.startTest();
        CaseTriggerUtility.captureErrorMsg('Test Error', 'User', JSON.serialize(caseMap));
        CaseTriggerUtility.captureErrorMsg('Test Error', 'Contact', JSON.serialize(caseMap));
        CaseTriggerUtility.captureErrorMsg('Test Error', 'Project Resource', JSON.serialize(caseMap));
        Test.stopTest();
        
    }
    // @IsTest
    // static void testEnqueueCaseJob(){
    //     Id compassRecTypeId = [Select Id from RecordType WHERE Name = 'Onboarding'].Id;
    //     String emailBody = 'First Name: Juan \n'+
    //     'Last Name: dela Cruz \n'+
    //     'Email: userbe@ncc.example.com \n'+
    //     'Title: Test Title \n'+
    //     'City: City \n'+
    //     'State: State \n'+
    //     'Country: United States \n'+
    //     'Role: New Role \n'+
    //     'Manager: Iamca Cagurangan \n'+
    //     'Employment Status: 1099 \n'+
    //     'Start Date: 2021-07-20 \n'+
    //     'Aligned Project: none \n'+
    //     'Need Phone: Y \n'+
    //     'Need Laptop vs Computer: Y \n'+
    //     'Task for Skills Inventory: \n'+
    //     'Tasks for PIV and/or CAC: \n'+
    //     'Tasks for Tailored Resume: \n'+
    //     'Bio: \n'+
    //     'Brief Summary Section: \n'+
    //     'NCC Channel: \n'+
    //     'CPM NCC Internal Code Needed?: Y \n'+
    //     'CPM Title: Dev \n'+
    //     'Salesforce Access requirements: Project Contributor';
    //   	Case newCaseRec = new Case(Status = 'New', Description = emailBody, Subject = 'Onboarding Johnny Doe | W2');
        
    //     Test.startTest();
    //     	insert newCaseRec;
    //     Test.stopTest();
    // }
    
    // @IsTest
    // static void testSwitchTriggerFalse(){
    //     Apex_Trigger_Switch__c switchh = new Apex_Trigger_Switch__c();
    //     switchh.Name = 'CaseTrigger';
    //     switchh.Active__c = false;
    //     insert switchh;
    //     String emailBody = 'First Name: Juan \n'+
    //     'Last Name: dela Cruz \n'+
    //     'Email: userbe@ncc.example.com \n'+
    //     'Title: Test Title \n'+
    //     'City: City \n'+
    //     'State: State \n'+
    //     'Country: United States \n'+
    //     'Role: New Role \n'+
    //     'Manager: Iamca Cagurangan \n'+
    //     'Employment Status: 1099 \n'+
    //     'Start Date: 2021-07-20 \n'+
    //     'Aligned Project: none \n'+
    //     'Need Phone: Y \n'+
    //     'Need Laptop vs Computer: Y \n'+
    //     'Task for Skills Inventory: \n'+
    //     'Tasks for PIV and/or CAC: \n'+
    //     'Tasks for Tailored Resume: \n'+
    //     'Bio: \n'+
    //     'Brief Summary Section: \n'+
    //     'NCC Channel: \n'+
    //     'CPM NCC Internal Code Needed?: Y \n'+
    //     'CPM Title: Dev \n'+
    //     'Salesforce Access requirements: Project Contributor';
    //   	Case newCaseRec = new Case(Status = 'New', Description = emailBody, Subject = 'Onboarding Johnny Doe | W2');
    //     Test.startTest();	
    //     	insert newCaseRec;
    //     Test.stopTest();
    // }
    
}