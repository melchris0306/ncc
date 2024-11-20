@isTest
public class CloneTestExecutionScreenCtrlTest {

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
        }
        
        Id accCustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        Account customerAccount = new Account();
        customerAccount.Name = 'Test Account #1';
        customerAccount.RecordTypeId = accCustomerRecordTypeId;
        insert customerAccount;
        
        Project__c projRecord = new Project__c();
        projRecord.Project_Code__c = '0000';
        projRecord.Name = 'Test Project #A';
        projRecord.Account__c = customerAccount.Id;
        projRecord.Starting_Task_Number__c = 0;
        projRecord.Task_Number_Display_Format__c = '{mm}';
        projRecord.Project_Code__c = 'PROJ';
        
        insert projRecord;
        
        Project__c projRecord2 = new Project__c();
        projRecord2.Project_Code__c = '0000';
        projRecord2.Name = 'Test Project #B';
        projRecord2.Account__c = customerAccount.Id;
        projRecord.Starting_Task_Number__c = 0;
        projRecord2.Task_Number_Display_Format__c = '{mm}';
        projRecord2.Project_Code__c = 'PRO';
        
        insert projRecord2;


        Epic__c epicRecord1 = new Epic__c();
        epicRecord1.Epic_Code__c = 'EPI';
        epicRecord1.Name = 'Test Epic #A';
        epicRecord1.Epic_Code__c = 'EPI';
        epicRecord1.Project__c = projRecord.Id;

        insert epicRecord1;
        
        
        Sprint__c dBacklogSprint = new Sprint__c();
        dBacklogSprint.Name = 'Backlog (Test Project #A)';
        dBacklogSprint.Project__c = projRecord.Id;
        insert dBacklogSprint;
        
        
        List<Sprint__c> sprintList = new List<Sprint__c>();
        for(Integer i = 1; i < 5; i++){
            Sprint__c sprint = new Sprint__c();
            sprint.Name = 'Sample Sprint ' + i+1;
            sprint.Project__c = projRecord.Id;
            sprint.Start_Date__c = System.today(); 
            sprint.End_Date__c = Date.valueOf(System.today()).addDays(30); 
            
            if(i > 1){
                sprint.Start_Date__c = Date.valueOf(System.today()).addDays((30*i)+1); 
                sprint.End_Date__c = Date.valueOf(System.today()).addDays((30*i+1)+1);  
            }
            sprintList.add(sprint);
        }
        insert sprintList;

        Id qaRecType = [Select Id from RecordType WHERE Name = 'QA'].Id;
        List<Project_Task__c> projTaskList = new List<Project_Task__c>();

        Project_Task__c qaBugRecord = new Project_Task__c();
        qaBugRecord.Project__c = projRecord.Id;
        qaBugRecord.Epic__c = epicRecord1.Id;
        qaBugRecord.RecordTypeId = qaRecType;
        qaBugRecord.Name = 'Next';
        qaBugRecord.Title__c = 'QA: Test';
        qaBugRecord.Alternative_Title__c = 'QA Record';
        projTaskList.add(qaBugRecord);
        insert projTaskList;
    }
    
    @isTest
    public static void getData_Test(){
        Id qaRecType = [Select Id from RecordType WHERE Name = 'QA'].Id;
        
        Project__c projRecord = [SELECT Id, Name, OwnerId FROM Project__c WHERE Name = 'Test Project #A' LIMIT 1];
        Epic__c epicRecord = [SELECT Id, Name FROM Epic__c WHERE Name = 'Test Epic #A' LIMIT 1];
        Project_Task__c fpt = [SELECT Id FROM Project_Task__c WHERE Alternative_Title__c = 'QA Record' LIMIT 1];
        User owner = [Select Id From User LIMIT 1];
        Test.startTest();
        
        Test_Execution__c testExecutionFromButton = new Test_Execution__c();
        testExecutionFromButton.Assigned_To__c = owner.Id;
        testExecutionFromButton.From_Test_Execution_Button__c = TRUE;
        testExecutionFromButton.Project__c = projRecord.Id;
        testExecutionFromButton.Epic__c = epicRecord.Id;
        testExecutionFromButton.QA_Task__c = [SELECT Id FROM Project_Task__c WHERE RecordTypeId =: qaRecType LIMIT 1].Id;
        testExecutionFromButton.Feature__c = fpt.Id;
        testExecutionFromButton.Testing_Phase__c = 'System Integration Testing';
            
        insert testExecutionFromButton;
        
        	CloneTestExecutionScreenController.getData([SELECT Id FROM Project_Task__c LIMIT 1].Id);
        Test.stopTest();
    }
    
     @isTest
    public static void getTestExecutionsById_Test(){
        
        
        Test.startTest();
        Id qaRecType = [Select Id from RecordType WHERE Name = 'QA'].Id;
        
        Project__c projRecord = [SELECT Id, Name, OwnerId FROM Project__c WHERE Name = 'Test Project #A' LIMIT 1];
        Epic__c epicRecord = [SELECT Id, Name FROM Epic__c WHERE Name = 'Test Epic #A' LIMIT 1];
        Project_Task__c fpt = [SELECT Id FROM Project_Task__c WHERE Alternative_Title__c = 'QA Record' LIMIT 1];
        User owner = [Select Id From User LIMIT 1];
        
        Test_Execution__c testExecutionFromButton = new Test_Execution__c();
        testExecutionFromButton.Assigned_To__c = owner.Id;
        testExecutionFromButton.From_Test_Execution_Button__c = TRUE;
        testExecutionFromButton.Project__c = projRecord.Id;
        testExecutionFromButton.Epic__c = epicRecord.Id;
        testExecutionFromButton.QA_Task__c = [SELECT Id FROM Project_Task__c WHERE RecordTypeId =: qaRecType LIMIT 1].Id;
        testExecutionFromButton.Feature__c = fpt.Id;
        testExecutionFromButton.Testing_Phase__c = 'System Integration Testing';
            
        insert testExecutionFromButton;
        CloneTestExecutionScreenController.getTestExecutionsById(new List<String>{[SELECT Id FROM Test_Execution__c].Id});
        Test.stopTest();
        
    }
}