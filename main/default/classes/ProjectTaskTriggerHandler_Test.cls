/**
* @description ProjectTaskTriggerHandler Test class for the following:
*           - ProjectTaskTrigger
*           - ProjectTaskTriggerHandler
*           - ProjectTaskTriggerUtility
*           05/12/2021 - Kyzer Buhay - Test Class creation
**/
@IsTest
public class ProjectTaskTriggerHandler_Test {
    @TestSetup
    static void createData(){
        User ceoUser = [SELECT Id, UserRole.DeveloperName FROM User WHERE UserRole.DeveloperName='CEO' AND isActive = True LIMIT 1];
        System.runAs ( ceoUser ) {
            Profile compassAgilePMUserId = [SELECT Id FROM Profile WHERE Name = 'Compass Agile PM User'];
            //UserRole r = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'UlappCustomerUser' LIMIT 1];
          
            Account ac = new Account(name ='Ulapp');
            insert ac; 
           
            Contact con = new Contact(LastName ='testCon',AccountId = ac.Id, Email='test1@com.com');
            insert con;  
                      
            User user = new User(alias = 'test123', email='test123@noemail.com',
                    emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                    localesidkey='en_US', country='United States',IsActive =true,
                    ContactId = con.Id, PortalRole='Manager',
                    timezonesidkey='America/Los_Angeles', username='tester@noemail.com', profileid = compassAgilePMUserId.Id);
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
        projRecord.Project_Code__c = '0000';
        projRecord.Name = 'Test Project #A';
        projRecord.Account__c = customerAccount.Id;
        projRecord.Starting_Task_Number__c = 0;
        projRecord.Task_Number_Display_Format__c = '{mm}';
        projRecord.Project_Code__c = 'PROJ';
        projRecord.Do_Not_Require_Sprint__c = true;
        
        insert projRecord;
        
        Project__c projRecord2 = new Project__c();
        projRecord2.Project_Code__c = '0000';
        projRecord2.Name = 'Test Project #B';
        projRecord2.Account__c = customerAccount.Id;
        projRecord2.Starting_Task_Number__c = 0;
        projRecord2.Task_Number_Display_Format__c = '{mm}';
        projRecord2.Project_Code__c = 'PRO';
        projRecord2.Do_Not_Require_Sprint__c = true;
        insert projRecord2;


        Epic__c epicRecord1 = new Epic__c();
        epicRecord1.Epic_Code__c = 'EPI';
        epicRecord1.Name = 'Test Epic #A';
        epicRecord1.Epic_Code__c = 'EPI';
        epicRecord1.Project__c = projRecord.Id;

        insert epicRecord1;
        
        Workplan__c wp1 = new Workplan__c();
        wp1.Project__c = projRecord.Id;
        wp1.Epic__c = epicRecord1.Id;
        wp1.Name = 'WP Test Class 1';
        wp1.Status__c = 'New';
        insert wp1;
        
        Sprint__c dBacklogSprint = new Sprint__c();
        dBacklogSprint.Name = 'Backlog (Test Project #A)';
        dBacklogSprint.Project__c = projRecord.Id;
        dBacklogSprint.Start_Date__c = System.today(); 
        dBacklogSprint.End_Date__c = Date.valueOf(System.today()).addDays(30);
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
        
        
        Project__c queriedProjRecordA = [SELECT Id, Default_Backlog__c FROM Project__c WHERE Id =: projRecord.Id LIMIT 1];
        Sprint__c queriedSprintA = [SELECT Id, Name, End_Date__c FROM Sprint__c WHERE Project__c =: queriedProjRecordA.Id LIMIT 1];
        queriedProjRecordA.Default_Backlog__c = dBacklogSprint.Id;
        //system.assertequals(queriedSprintA, null);
        update queriedProjRecordA;        

        Account ac = new Account(name ='Ulapp2');
        insert ac;
        Contact con = new Contact(LastName ='testCon2',AccountId = ac.Id, Email='test2@com.com');
        insert con;  
        Id featureRecType = [Select Id from RecordType WHERE Name = 'Feature'].Id;
        Id qaRecType = [Select Id from RecordType WHERE Name = 'QA'].Id;
        Id devRecType = [Select Id from RecordType WHERE Name = 'Dev'].Id;
        Id storyRecType = [Select Id from RecordType WHERE Name = 'Story'].Id;
        List<Project_Task__c> projTaskList = new List<Project_Task__c>();

        Project_Task__c featureRecord = new Project_Task__c();
        featureRecord.Alternative_Title__c = 'Feature Record';
        featureRecord.Project__c = queriedProjRecordA.Id;
        featureRecord.Epic__c = epicRecord1.Id;
        featureRecord.Sprint__c = queriedSprintA.Id;
        featureRecord.Assigned_To__c = con.Id;
        featureRecord.Feature_Code__c = 'FEA';
        featureRecord.RecordTypeId = featureRecType;
        featureRecord.Title__c = 'FE: TestFeature';
        featureRecord.Start_Date__c = System.today();
        featureRecord.Target_Resolution_Date__c = System.today() + 1;
        featureRecord.Assigned_Developer__c = con.Id;
        projTaskList.add(featureRecord);
        

        Project_Task__c qaBugRecord = new Project_Task__c();
        qaBugRecord.Project__c = projRecord.Id;
        qaBugRecord.Epic__c = epicRecord1.Id;
        qaBugRecord.Sprint__c = queriedSprintA.Id;
        qaBugRecord.RecordTypeId = qaRecType;
        qaBugRecord.Name = 'Next';
        qaBugRecord.Title__c = 'QA: Test';
        qaBugRecord.Alternative_Title__c = 'QA Record';
        qaBugRecord.Start_Date__c = System.today();
        qaBugRecord.Target_Resolution_Date__c = System.today() + 1;
        qaBugRecord.Assigned_Developer__c = con.Id;
        qaBugRecord.Sign_off_Technical_Review__c = true;
        qaBugRecord.SIT_Assigned_To__c = con.Id;
        qaBugRecord.UAT_Assigned_To__c = con.Id;
        qaBugRecord.Prod_Validation_Assigned_To__c = con.Id;
        projTaskList.add(qaBugRecord);
        

        Project_Task__c devRecord = new Project_Task__c();
        devRecord.From_DevQA_Button_Story__c = True;
        devRecord.Project__c = projRecord.Id;
        devRecord.Epic__c = epicRecord1.Id;
        devRecord.Sprint__c = queriedSprintA.Id;
        devRecord.RecordTypeId = devRecType;
        devRecord.Name = 'Next_Nikki';
        devRecord.Title__c = 'Test';
        devRecord.Status__c = 'New';
        devRecord.Estimated_Hours__c = 1;
        devRecord.Proposed_Hours__c = 1;
        devRecord.From_DevQA_Button_Story__c = false;
        devRecord.From_DevQA_Button_Functionality__c = false;
        devRecord.From_Bug_Button__c = false;
        devRecord.Start_Date__c = System.today();
        devRecord.Target_Resolution_Date__c = System.today() + 1;
        devRecord.Assigned_Developer__c = con.Id;
        devRecord.Sign_off_Technical_Review__c = true;
        projTaskList.add(devRecord);
        
        Project_Task__c storyToFeature = new Project_Task__c();
        storyToFeature.Alternative_Title__c = 'Sample Project Task A';
        storyToFeature.Project__c = projRecord.Id;
        storyToFeature.Epic__c = epicRecord1.Id;
        storyToFeature.Assigned_To__c = con.Id;
        storyToFeature.RecordTypeId = storyRecType;
        storyToFeature.Convert_To_Feature__c = false;
        storyToFeature.Start_Date__c = System.today();
        storyToFeature.Target_Resolution_Date__c = System.today() + 1;
        storyToFeature.Assigned_Developer__c = con.Id;
        projTaskList.add(storyToFeature);
        
        insert projTaskList;

        //Update to account for new Project task VRs -Nikki 04/06/2022
        List<Project_Task__c> queriedProjTaskList = [SELECT Id FROM Project_Task__c];
        Contact testContact = [Select Id FROM Contact LIMIT 1];
        List<Project_Task_Log__c> projTaskLogList = new List<Project_Task_Log__c>();
        

        for(Project_Task__c prjTsk : queriedProjTaskList){
            Project_Task_Log__c prjTskLog = new Project_Task_Log__c();
            prjTskLog.Project_Task__c = prjTsk.Id;
            prjTskLog.Hours__c = 1;
            prjTskLog.Date__c = System.today();
            prjTskLog.Comments__c = 'Test_Mats';
            prjTskLog.Contact__c = testContact.Id;

            projTaskLogList.add(prjTskLog);
        }

        insert projTaskLogList;
    }
    
    @IsTest
    static void processSprintTestWithActiveSprint(){
        Project__c queriedProjRecordA = [SELECT Id FROM Project__c LIMIT 1];
        Id bugRecTypeId = [Select Id from RecordType WHERE Name = 'Bug'].Id;
        List<String> ptStatus = new List<String>{'', 'Monitoring', 'In Progress'};
        Test.startTest();
        //Inserting project tasks without Sprints
            List<Project_Task__c> projTaskList = new List<Project_Task__c>();
            for(Integer i = 0; i < 3; i ++){
                Project_Task__c projTask = new Project_Task__c();
                projTask.Alternative_Title__c = 'Sample Project Task ' + i;
                projTask.Project__c = queriedProjRecordA.Id;
                projTask.Status__c = ptStatus[i];
                projTask.RecordTypeId = bugRecTypeId;
                projTaskList.add(projTask);
            }
            insert projTaskList;
            
            List<Project_Task__c> queriedProjTasks = [SELECT Id, Sprint__c FROM Project_Task__c];
            //for(Project_Task__c pt : queriedProjTasks){
            //  System.assert(!String.isBlank(String.valueOf(pt.Sprint__c)));
            //}
        Test.stopTest();
    }
    
    @IsTest
    static void processSprintTestWithoutActiveSprint(){
        Project__c queriedProjRecordA = [SELECT Id FROM Project__c LIMIT 1];
        Id bugRecTypeId = [Select Id from RecordType WHERE Name = 'Bug'].Id;
        List<String> ptStatus = new List<String>{'', 'Monitoring', 'In Progress'};
        Test.startTest();
        Sprint__c activeSprint = [SELECT Id, Start_Date__c FROM Sprint__c WHERE Start_Date__c =: System.today() LIMIT 1];
        delete activeSprint;
        //Inserting project tasks without Sprints
            List<Project_Task__c> projTaskList = new List<Project_Task__c>();
            for(Integer i = 0; i < 3; i ++){
                Project_Task__c projTask = new Project_Task__c();
                projTask.Alternative_Title__c = 'Sample Project Task ' + i;
                projTask.Project__c = queriedProjRecordA.Id;
                projTask.Status__c = ptStatus[i];
                projTask.RecordTypeId = bugRecTypeId;
                projTaskList.add(projTask);
            }
            
            insert projTaskList;
            
            List<Project_Task__c> queriedProjTasks = [SELECT Id, Alternative_Title__c, Sprint__c, Sprint__r.Start_Date__c FROM Project_Task__c];
            //for(Project_Task__c pt : queriedProjTasks){
            //  System.assert(!String.isBlank(String.valueOf(pt.Sprint__c)));
            //}
        Test.stopTest();
    }
    
    @IsTest
    static void processSprintTestUpdateWithEmptySprint(){
         Test.startTest();
        Project__c queriedProjRecordA = [SELECT Id FROM Project__c LIMIT 1];
        Id bugRecTypeId = [Select Id from RecordType WHERE Name = 'Bug'].Id;
        List<String> ptStatus = new List<String>{'', 'Monitoring', 'In Progress'};
            //Inserting project tasks without Sprints
            List<Project_Task__c> projTaskList = new List<Project_Task__c>();
            for(Integer i = 0; i < 3; i ++){
                Project_Task__c projTask = new Project_Task__c();
                projTask.Alternative_Title__c = 'Sample Project Task ' + i;
                projTask.Project__c = queriedProjRecordA.Id;
                projTask.Status__c = ptStatus[i];
                projTask.RecordTypeId = bugRecTypeId;
                projTaskList.add(projTask);
            }
            insert projTaskList;
       
            //Remove sprints on Project Task Records then update
            List<Project_Task__c> queriedProjTasks = [SELECT Id, Sprint__c FROM Project_Task__c];
            List<Project_Task__c> ptToUpdate = new List<Project_Task__c>();
            for(Project_Task__c pt : queriedProjTasks){
                pt.Sprint__c = null;
                ptToUpdate.add(pt);
            }
            update ptToUpdate;
        Test.stopTest();
    }
    
    @IsTest
    static void processprocessAssignedToAsOwnerTest(){
        Test.startTest();
        Project__c projRecord = [SELECT Id, Name FROM Project__c WHERE Name = 'Test Project #A' LIMIT 1];
        Workplan__c workplanRecord = [SELECT Id, Name FROM Workplan__c LIMIT 1];
        Id bugRecTypeId = [Select Id from RecordType WHERE Name = 'Bug'].Id;
        Project_Task__c projTaskA = new Project_Task__c();
        projTaskA.Alternative_Title__c = 'Sample Project Task A';
        projTaskA.Project__c = projRecord.Id;
        projTaskA.RecordTypeId = bugRecTypeId;
        projTaskA.Workplan__c = workplanRecord.Id;
        projTaskA.Start_Date__c = System.now().date().addDays(-15);
        projTaskA.Target_Resolution_Date__c  = System.now().date().addDays(15);
        insert projTaskA;
        
        Contact con = [SELECT Id, LastName FROM Contact WHERE LastName = 'testCon' LIMIT 1];
        
            projTaskA.Assigned_To__c = con.Id;
            update projTaskA;
        
        //User compassAgilePMUser = [SELECT Id, ContactId FROM User WHERE ContactId =: con.Id LIMIT 1];
        Project_Task__c updatedPT = [SELECT Id, OwnerId, Assigned_To__c, Alternative_Title__c 
                              FROM Project_Task__c WHERE Alternative_Title__c = 'Sample Project Task A' LIMIT 1];
        
        //System.assertEquals(compassAgilePMUser.Id, updatedPT.OwnerId);
        Test.stopTest();
    }
    
    @IsTest
    static void processAssignedToAsOwner_WithoutMatchingEmailTest(){
        Test.startTest();
        Project__c projRecord = [SELECT Id, Name, OwnerId FROM Project__c WHERE Name = 'Test Project #A' LIMIT 1];
        Id bugRecTypeId = [Select Id from RecordType WHERE Name = 'Bug'].Id;
        Contact con = [SELECT id FROM Contact where LastName='testCon2'];
        
            
            Project_Task__c projTaskA = new Project_Task__c();
            projTaskA.Alternative_Title__c = 'Sample Project Task A';
            projTaskA.Project__c = projRecord.Id;
            projTaskA.Assigned_To__c = con.Id;
            projTaskA.RecordTypeId = bugRecTypeId;
            insert projTaskA;
        Test.stopTest();
        Project_Task__c updatedPT = [SELECT Id, OwnerId, Assigned_To__c, Alternative_Title__c 
                              FROM Project_Task__c WHERE Alternative_Title__c = 'Sample Project Task A' LIMIT 1];
        
    }

    @IsTest
    static void createFeatureFunctionality(){
        Test.startTest();
        Project__c projRecord = [SELECT Id, Name, OwnerId FROM Project__c WHERE Name = 'Test Project #A' LIMIT 1];
        Epic__c epicRecord = [SELECT Id, Name FROM Epic__c WHERE Name = 'Test Epic #A' LIMIT 1];
        Id storyRecType = [Select Id from RecordType WHERE Name = 'Story'].Id;
        Id featureRecType = [Select Id from RecordType WHERE Name = 'Feature'].Id;
        Id functionalityRecType = [Select Id from RecordType WHERE Name = 'Functionality'].Id;
        List<Project_Task__c> projTaskList = new List<Project_Task__c>();
        List<Project_Task__c> projTaskListToUpdate = new List<Project_Task__c>();
        Contact con = [SELECT id FROM Contact where LastName='testCon2'];
		
        
        Project_Task__c storyToFeature = new Project_Task__c();
        storyToFeature.Alternative_Title__c = 'Sample Project Task A';
        storyToFeature.Project__c = projRecord.Id;
        storyToFeature.Epic__c = epicRecord.Id;
        storyToFeature.Assigned_To__c = con.Id;
        storyToFeature.RecordTypeId = storyRecType;
        storyToFeature.Convert_To_Feature__c = false;
        projTaskList.add(storyToFeature);

        Project_Task__c storyToFunctionality = new Project_Task__c();
        storyToFunctionality.Alternative_Title__c = 'Sample Project Task B';
        storyToFunctionality.Project__c = projRecord.Id;
        storyToFunctionality.Epic__c = epicRecord.Id;
        storyToFunctionality.Assigned_To__c = con.Id;
        storyToFunctionality.RecordTypeId = storyRecType;
        projTaskList.add(storyToFunctionality);

        insert projTaskList;
        
        for(Project_Task__c prj: projTaskList){
            if(prj.Alternative_Title__c == 'Sample Project Task A'){
                prj.Convert_To_Feature__c = true;
            }
            else{
                prj.Convert_To_Functionality__c = true;
            }
            projTaskListToUpdate.add(prj);
        }
        
        update projTaskListToUpdate;
        Test.stopTest();
    }

    @IsTest
    static void createFunctionalityFromButton(){
        Test.startTest();
        Project__c projRecord = [SELECT Id, Name, OwnerId FROM Project__c WHERE Name = 'Test Project #A' LIMIT 1];
        Epic__c epicRecord = [SELECT Id, Name FROM Epic__c WHERE Name = 'Test Epic #A' LIMIT 1];
        //Id featureRecType = [Select Id from RecordType WHERE Name = 'Feature'].Id;
        Id functionalityRecType = [Select Id from RecordType WHERE Name = 'Functionality'].Id;
        //List<Project_Task__c> projTaskList = new List<Project_Task__c>();
        //List<Project_Task__c> projTaskListToUpdate = new List<Project_Task__c>();
       
        Contact con = [SELECT id FROM Contact where LastName='testCon2'];
        
        
        Project_Task__c fpt = [SELECT Id FROM Project_Task__c WHERE Alternative_Title__c = 'Feature Record' LIMIT 1];
        //projTaskList = new List<Project_Task__c>();
        Project_Task__c functionalityFromAButton = new Project_Task__c();
        functionalityFromAButton.Alternative_Title__c = 'Sample Project Task A';
        functionalityFromAButton.Project__c = projRecord.Id;
        functionalityFromAButton.Epic__c = epicRecord.Id;
        functionalityFromAButton.Assigned_To__c = con.Id;
        functionalityFromAButton.Functionality_Code__c = 'FUN';
        functionalityFromAButton.From_Functionality_Button__c = true;
        functionalityFromAButton.RecordTypeId = functionalityRecType;
        functionalityFromAButton.Feature__c = fpt.Id;
        functionalityFromAButton.Title__c = 'FE: TestFeature';
        //projTaskList.add(functionalityFromAButton);
        
        insert functionalityFromAButton;
        Test.stopTest();
    }


    @IsTest
    static void createDevQaFromAButton(){
        Test.startTest();
        Project__c projRecord = [SELECT Id, Name, OwnerId FROM Project__c WHERE Name = 'Test Project #A' LIMIT 1];
        Epic__c epicRecord = [SELECT Id, Name FROM Epic__c WHERE Name = 'Test Epic #A' LIMIT 1];
        Id devRecType = [Select Id from RecordType WHERE Name = 'Dev'].Id;
        Id storyRecType = [Select Id from RecordType WHERE Name = 'Story'].Id;
        List<Project_Task__c> projTaskList = new List<Project_Task__c>();
        List<Project_Task__c> projTaskListToUpdate = new List<Project_Task__c>();
        Contact con = [SELECT id FROM Contact where LastName='testCon2'];
      
        Project_Task__c devRecord = new Project_Task__c();
        devRecord.From_DevQA_Button_Story__c = True;
        devRecord.Project__c = projRecord.Id;
        devRecord.Epic__c = epicRecord.Id;
        devRecord.RecordTypeId = devRecType;
        devRecord.Name = 'Next';
        devRecord.Title__c = 'Test';
        devRecord.Estimated_Hours__c = 1;
        devRecord.Proposed_Hours__c = 1;
        projTaskList.add(devRecord);

        devRecord = new Project_Task__c();
        devRecord.From_DevQA_Button_Functionality__c = True;
        devRecord.Project__c = projRecord.Id;
        devRecord.Epic__c = epicRecord.Id;
        devRecord.RecordTypeId = devRecType;
        devRecord.Name = 'Next';
        devRecord.Title__c = 'FU: Test';
        devRecord.Estimated_Hours__c = 1;
        devRecord.Proposed_Hours__c = 1;
        projTaskList.add(devRecord);

        
        insert projTaskList;
        Test.stopTest();
    }

    @IsTest
    static void createDevQaFromAButtonError(){
        Test.startTest();
        Project__c projRecord = [SELECT Id, Name, OwnerId FROM Project__c WHERE Name = 'Test Project #A' LIMIT 1];
        Epic__c epicRecord = [SELECT Id, Name FROM Epic__c WHERE Name = 'Test Epic #A' LIMIT 1];
        Id devRecType = [Select Id from RecordType WHERE Name = 'Dev'].Id;
        List<Project_Task__c> projTaskList = new List<Project_Task__c>();
        List<Project_Task__c> projTaskListToUpdate = new List<Project_Task__c>();
        Contact con = [SELECT id FROM Contact where LastName='testCon2'];
		
        
        Project_Task__c devRecord = new Project_Task__c();
        devRecord.From_DevQA_Button_Story__c = True;
        devRecord.RecordTypeId = devRecType;
        devRecord.Name = 'Next';
        devRecord.Title__c = 'Test';
        projTaskList.add(devRecord);

        devRecord = new Project_Task__c();
        devRecord.From_DevQA_Button_Functionality__c = True;
        devRecord.RecordTypeId = devRecType;
        devRecord.Name = 'Next';
        devRecord.Title__c = 'FU: Test';
        projTaskList.add(devRecord);

        try {
            insert projTaskList;
        } catch (DmlException e) {
            //system.assertequals(e.getMessage().contains('Please populate the following field(s)'), true);
        }
        Test.stopTest();
    }

    @IsTest
    static void createBugFromQA(){
        Test.startTest();
        Project__c projRecord = [SELECT Id, Name, OwnerId FROM Project__c WHERE Name = 'Test Project #A' LIMIT 1];
        Epic__c epicRecord = [SELECT Id, Name FROM Epic__c WHERE Name = 'Test Epic #A' LIMIT 1];
        Id bugRecType = [Select Id from RecordType WHERE Name = 'Bug'].Id;
             
        Project_Task__c qpt = [SELECT Id FROM Project_Task__c WHERE Alternative_Title__c = 'QA Record' LIMIT 1];

        Project_Task__c qaBugRecord = new Project_Task__c();
        qaBugRecord.From_Bug_Button__c = True;
        qaBugRecord.Project__c = projRecord.Id;
        qaBugRecord.Epic__c = epicRecord.Id;
        qaBugRecord.RecordTypeId = bugRecType;
        qaBugRecord.Name = 'Next';
        qaBugRecord.Title__c = 'QA: Test';
        qaBugRecord.QA_Task__c = qpt.Id;
		
        insert qaBugRecord;
        Test.stopTest();
    }

    @IsTest
    static void storePreviousTaskNumber(){
        Test.startTest();
        Project__c projRecord = [SELECT Id, Name, OwnerId FROM Project__c WHERE Name = 'Test Project #A' LIMIT 1];
        Project__c projRecord2 = [SELECT Id, Name, OwnerId FROM Project__c WHERE Name = 'Test Project #B' LIMIT 1];
        Epic__c epicRecord = [SELECT Id, Name FROM Epic__c WHERE Name = 'Test Epic #A' LIMIT 1];
        Id storyRecType = [Select Id from RecordType WHERE Name = 'Story'].Id;
        Id featureRecType = [Select Id from RecordType WHERE Name = 'Feature'].Id;
        Id functionalityRecType = [Select Id from RecordType WHERE Name = 'Functionality'].Id;
        Contact con = [SELECT id FROM Contact where LastName='testCon2'];

        
        Project_Task__c storyToFeature = new Project_Task__c();
        storyToFeature.Alternative_Title__c = 'Sample Project Task A';
        storyToFeature.Project__c = projRecord.Id;
        storyToFeature.Epic__c = epicRecord.Id;
        storyToFeature.Assigned_To__c = con.Id;
        storyToFeature.RecordTypeId = storyRecType;
        storyToFeature.Convert_To_Feature__c = false;
        insert storyToFeature;

        storyToFeature.Project__c = projRecord2.Id;
        update storyToFeature;
        Test.stopTest();
    }

    //CAPM-AGL-11-DV Test for Related QA Tasks' Status if Dev/Bug Task Status is For QA
    @IsTest
    static void processUpdateDevStatus(){
		Test.startTest();
        Id devRecType = [Select Id from RecordType WHERE Name = 'Dev'].Id;
        List<Project_Task__c> projTaskList = [Select Id, Status__c FROM Project_Task__c WHERE RecordTypeId = :devRecType];
        List<Project_Task__c> projTaskListToUpdate = new List<Project_Task__c>();
        Set<Id> devTaskId = new Set<Id>();

        for(Project_Task__c prjtsk : projTaskList){
            prjtsk.Status__c = 'For QA';
            projTaskListToUpdate.add(prjtsk);
            devTaskId.add(prjtsk.Id);
        }

        
        update projTaskListToUpdate;
        

        Project_Task__c qaRecord = [Select Id, Status__c FROM Project_Task__c WHERE Dev_Task__c IN :devTaskId LIMIT 1];
        System.assertEquals('New', qaRecord.Status__c);
		Test.stopTest();
    }

    //CAPM-AGL-11-DV Test for Related Dev/Bug tasks' Status if QA Task Status = Pass and Smoke QA Sign-off = true
    @IsTest
    static void processUpdateQAStatus(){
		Test.startTest();
        Id qaRecType = [Select Id from RecordType WHERE Name = 'QA'].Id;
        List<Project_Task__c> projTaskList = [Select Id, Status__c, Sign_off_Smoke__c, Dev_Task__c FROM Project_Task__c WHERE RecordTypeId = :qaRecType AND Dev_Task__c != NULL];
        List<Project_Task__c> projTaskListToUpdate = new List<Project_Task__c>();
        List<Project_Task__c> projTaskListToUpdateAgain = new List<Project_Task__c>();
        Set<Id> devTaskId = new Set<Id>();
        Project_Task_Log__c prjTskLog = new Project_Task_Log__c();
		Account ac = new Account(name ='Ulapp3');
        insert ac;
        Contact con = new Contact(LastName ='testCon32',AccountId = ac.Id, Email='test23@co23m.com');
        insert con; 
        
        for(Project_Task__c prjtsk : projTaskList){
            prjtsk.Status__c = 'Pass';
			prjtsk.SIT_Assigned_To__c = con.Id;
        	prjtsk.UAT_Assigned_To__c = con.Id;
            prjtsk.Prod_Validation_Assigned_To__c = con.Id;
            prjtsk.Sign_off_Smoke__c = true;
            projTaskListToUpdate.add(prjtsk);
            devTaskId.add(prjtsk.Dev_Task__c);
        }

        
        update projTaskListToUpdate;

        Project_Task__c devRecord = [Select Id, Status__c FROM Project_Task__c WHERE Id = :devTaskId LIMIT 1];
        Test.stopTest();
        //System.assertEquals('For Release', devRecord.Status__c);

    }
    
    @IsTest
    static void processUpdateQAStatusEmailNotif_SIT(){
		Test.startTest();
        Id qaRecType = [Select Id from RecordType WHERE Name = 'QA'].Id;
        List<Project_Task__c> projTaskList = [Select Id, Status__c, Sign_off_Smoke__c, Dev_Task__c FROM Project_Task__c WHERE RecordTypeId = :qaRecType AND Dev_Task__c != NULL];
        List<Project_Task__c> projTaskListToUpdate = new List<Project_Task__c>();
        List<Project_Task__c> projTaskListToUpdateAgain = new List<Project_Task__c>();
        Set<Id> devTaskId = new Set<Id>();
        Project_Task_Log__c prjTskLog = new Project_Task_Log__c();
		Account ac = new Account(name ='Ulapp3');
        insert ac;
        Contact con = new Contact(LastName ='testCon32',AccountId = ac.Id, Email='test23@co23m.com');
        insert con; 
        
        for(Project_Task__c prjtsk : projTaskList){
            prjtsk.Status__c = 'SIT';
			prjtsk.SIT_Assigned_To__c = con.Id;
        	prjtsk.UAT_Assigned_To__c = con.Id;
            prjtsk.Prod_Validation_Assigned_To__c = con.Id;
            projTaskListToUpdate.add(prjtsk);
            devTaskId.add(prjtsk.Dev_Task__c);
        }

        update projTaskListToUpdate;

        Project_Task__c devRecord = [Select Id, Status__c FROM Project_Task__c WHERE Id = :devTaskId LIMIT 1];
        Test.stopTest();
        //System.assertEquals('SIT', devRecord.Status__c);

    }
    
     @IsTest
    static void processUpdateQAStatusEmailNotif_UAT(){
		Test.startTest();
        Id qaRecType = [Select Id from RecordType WHERE Name = 'QA'].Id;
        List<Project_Task__c> projTaskList = [Select Id, Status__c, Sign_off_Smoke__c, Dev_Task__c FROM Project_Task__c WHERE RecordTypeId = :qaRecType AND Dev_Task__c != NULL];
        List<Project_Task__c> projTaskListToUpdate = new List<Project_Task__c>();
        List<Project_Task__c> projTaskListToUpdateAgain = new List<Project_Task__c>();
        Set<Id> devTaskId = new Set<Id>();
        Project_Task_Log__c prjTskLog = new Project_Task_Log__c();
		Account ac = new Account(name ='Ulapp3');
        insert ac;
        Contact con = new Contact(LastName ='testCon32',AccountId = ac.Id, Email='test23@co23m.com');
        insert con; 
        
        for(Project_Task__c prjtsk : projTaskList){
            prjtsk.Status__c = 'UAT';
			prjtsk.SIT_Assigned_To__c = con.Id;
        	prjtsk.UAT_Assigned_To__c = con.Id;
            prjtsk.Prod_Validation_Assigned_To__c = con.Id;
            projTaskListToUpdate.add(prjtsk);
            devTaskId.add(prjtsk.Dev_Task__c);
        }

        update projTaskListToUpdate;

        Project_Task__c devRecord = [Select Id, Status__c FROM Project_Task__c WHERE Id = :devTaskId LIMIT 1];
        Test.stopTest();
        //System.assertEquals('UAT', devRecord.Status__c);

    }
    
    @IsTest
    static void processUpdateQAStatusEmailNotif_ProdVAL(){
		Test.startTest();
        Id qaRecType = [Select Id from RecordType WHERE Name = 'QA'].Id;
        List<Project_Task__c> projTaskList = [Select Id, Status__c, Sign_off_Smoke__c, Dev_Task__c FROM Project_Task__c WHERE RecordTypeId = :qaRecType AND Dev_Task__c != NULL];
        List<Project_Task__c> projTaskListToUpdate = new List<Project_Task__c>();
        List<Project_Task__c> projTaskListToUpdateAgain = new List<Project_Task__c>();
        Set<Id> devTaskId = new Set<Id>();
        Project_Task_Log__c prjTskLog = new Project_Task_Log__c();
		Account ac = new Account(name ='Ulapp3');
        insert ac;
        Contact con = new Contact(LastName ='testCon32',AccountId = ac.Id, Email='test23@co23m.com');
        insert con; 
        
        for(Project_Task__c prjtsk : projTaskList){
            prjtsk.Status__c = 'Prod Validation';
			prjtsk.SIT_Assigned_To__c = con.Id;
        	prjtsk.UAT_Assigned_To__c = con.Id;
            prjtsk.Prod_Validation_Assigned_To__c = con.Id;
            projTaskListToUpdate.add(prjtsk);
            devTaskId.add(prjtsk.Dev_Task__c);
        }

        update projTaskListToUpdate;

        Project_Task__c devRecord = [Select Id, Status__c FROM Project_Task__c WHERE Id = :devTaskId LIMIT 1];
        Test.stopTest();
       // System.assertEquals('Prod Validation', devRecord.Status__c);

    }

    @IsTest
    static void computeStoryEstmatedHr(){
		Test.startTest();
        Project__c projRecord = [SELECT Id, Name, OwnerId FROM Project__c WHERE Name = 'Test Project #A' LIMIT 1];
        Epic__c epicRecord = [SELECT Id, Name FROM Epic__c WHERE Name = 'Test Epic #A' LIMIT 1];

        Id storyRecType = [Select Id from RecordType WHERE Name = 'Story'].Id;
        Id devRecType = [Select Id from RecordType WHERE Name = 'Dev'].Id;
       
        Project_Task__c storyRecord = new Project_Task__c();
        storyRecord.Project__c = projRecord.Id;
        storyRecord.RecordTypeId = storyRecType;
        storyRecord.Name = 'Story';
        storyRecord.Status__c = 'Converted';
        storyRecord.Estimated_Hours__c = 0;
        storyRecord.Proposed_Hours__c = 0;
        insert storyRecord;

        Project_Task__c devRecord = new Project_Task__c();
        devRecord.From_DevQA_Button_Story__c = True;
        devRecord.Project__c = projRecord.Id;
        devRecord.Epic__c = epicRecord.Id;
        devRecord.RecordTypeId = devRecType;
        devRecord.Estimated_Hours__c = 1;
        devRecord.Proposed_Hours__c = 1;
        devRecord.Name = 'Von_test';
        devRecord.Title__c = 'Test';
        devRecord.Status__c = 'New';
        devRecord.Source_Story__c = storyRecord.Id;
        insert devRecord;

            
            devRecord.Estimated_Hours__c = 3;
            devRecord.Proposed_Hours__c = 3;
            update devRecord;
        Test.stopTest();

    }

    @IsTest
    static void submitApprovalProcess(){
		Test.startTest();
        Project__c projRecord = [SELECT Id, Name, OwnerId FROM Project__c WHERE Name = 'Test Project #A' LIMIT 1];
        Epic__c epicRecord = [SELECT Id, Name FROM Epic__c WHERE Name = 'Test Epic #A' LIMIT 1];

        Id storyRecType = [Select Id from RecordType WHERE Name = 'Story'].Id;
        Id devRecType = [Select Id from RecordType WHERE Name = 'Dev'].Id;
       
        Project_Task__c storyRecord = new Project_Task__c();
        storyRecord.Project__c = projRecord.Id;
        storyRecord.RecordTypeId = storyRecType;
        storyRecord.Name = 'Story';
        storyRecord.Status__c = 'Converted';
        storyRecord.Proposed_Hours__c = 3;
        storyRecord.Estimated_Hours__c = 3;
        insert storyRecord;

        
            storyRecord.Status__c = 'For Approval';
            update storyRecord;
        Test.stopTest();
    }

    //CAPM-AGL-350-DV Test for Sprin Estimated Hrs
    @IsTest
    static void computeSprintEstimatedHrs(){
        List<Project_Task__c> projTskList = new List<Project_Task__c>();
		 Test.startTest();
        Project__c projRecord = [SELECT Id, Name, OwnerId FROM Project__c WHERE Name = 'Test Project #A' LIMIT 1];
        Epic__c epicRecord = [SELECT Id, Name FROM Epic__c WHERE Name = 'Test Epic #A' LIMIT 1];
        Sprint__C sprintRecord = [Select Id FROM Sprint__c WHERE Project__c =:projRecord.Id LIMIT 1];

        Id devRecType = [Select Id from RecordType WHERE Name = 'Dev'].Id;
       
        Project_Task__c devRecord = new Project_Task__c();
        devRecord.From_DevQA_Button_Story__c = True;
        devRecord.Project__c = projRecord.Id;
        devRecord.Epic__c = epicRecord.Id;
        devRecord.Sprint__c = sprintRecord.Id;
        devRecord.RecordTypeId = devRecType;
        devRecord.Estimated_Hours__c = 1;
        devRecord.Proposed_Hours__c = 1;
        devRecord.Name = 'Test_Est';
        devRecord.Title__c = 'Test';
        devRecord.Status__c = 'New';
        devRecord.Start_Date__c = System.today();
        devRecord.Target_Resolution_Date__c = System.today() + 1;
        insert devRecord;

        
       
        
        List<Project_Task__c> taskList = [Select Id, Estimated_Hours__c, Proposed_Hours__c FROM Project_Task__c WHERE Sprint__c =:sprintRecord.Id];
        for(Project_Task__c prjtskrec : taskList){
            prjtskrec.Estimated_Hours__c = 2;
            prjtskrec.Proposed_Hours__c = 2;
            projTskList.add(prjtskrec);
        }
        
        upsert projTskList;
        
        //Sprint__c recSprint = [Select Id, Estimated_Hours__c FROM Sprint__c WHERE Id =:sprintRecord.Id LIMIT 1];
        //System.assertEquals(2,recSprint.Estimated_Hours__c);
        Test.stopTest();
    }
    
    @IsTest
    static void storySubmitApprovalProcess(){
        Test.startTest();
        List<Project_Task__c> projTskList = new List<Project_Task__c>();

        Project__c projRecord = [SELECT Id, Name, OwnerId FROM Project__c WHERE Name = 'Test Project #A' LIMIT 1];
        Epic__c epicRecord = [SELECT Id, Name FROM Epic__c WHERE Name = 'Test Epic #A' LIMIT 1];
        Sprint__C sprintRecord = [Select Id FROM Sprint__c WHERE Project__c =:projRecord.Id LIMIT 1];

        Id storyRecType = [Select Id from RecordType WHERE Name = 'Story'].Id;

        List<Project_Task__c> taskList = [Select Id, Estimated_Hours__c, Proposed_Hours__c FROM Project_Task__c Where RecordTypeId=:storyRecType AND Status__c != null AND Status__c != 'For Approval' LIMIT 1];
        
        for(Project_Task__c prjtskrec : taskList){
            prjtskrec.Estimated_Hours__c = 2;
            prjtskrec.Proposed_Hours__c = 2;
            prjtskrec.Status__c = 'For Approval';
            projTskList.add(prjtskrec);
        }

        
            update projTskList;
        Test.stopTest();
    }

    @IsTest
    static void countNewOpenProjectTasks() {
        Test.startTest();
        Project__c project      = [SELECT Id FROM Project__c LIMIT 1];
        Contact contact         = [SELECT Id FROM Contact LIMIT 1];
        Workplan__c workPlan    = [SELECT Id, Total_Open_Project_Tasks__c FROM Workplan__c LIMIT 1];
        Id featureRecType       = [SELECT Id FROM RecordType WHERE Name = 'Story'].Id;

        
            Project_Task__c newProjectTask = new Project_Task__c();
            newProjectTask.Alternative_Title__c = 'Feature Record';
            newProjectTask.Project__c           = project.Id;
            newProjectTask.Assigned_To__c       = contact.Id;
            newProjectTask.RecordTypeId         = featureRecType;
            newProjectTask.Title__c             = 'Test Project Task';
            newProjectTask.Status__c            = 'New';
            newProjectTask.Workplan__c          = workPlan.Id;
            newProjectTask.Start_Date__c = System.today();
            newProjectTask.Target_Resolution_Date__c = System.today() + 1;
            
            insert newProjectTask;
        Test.stopTest();
    }

    @IsTest
    static void countProjectTasksUpdatedToOpen() {
        Test.startTest();
        Project__c project      = [SELECT Id FROM Project__c LIMIT 1];
        Contact contact         = [SELECT Id FROM Contact LIMIT 1];
        Workplan__c workPlan    = [SELECT Id, Total_Open_Project_Tasks__c FROM Workplan__c LIMIT 1];
        Id featureRecType       = [SELECT Id FROM RecordType WHERE Name = 'Story'].Id;

        Project_Task__c newProjectTask = new Project_Task__c();
        newProjectTask.Alternative_Title__c = 'Feature Record';
        newProjectTask.Project__c           = project.Id;
        newProjectTask.Assigned_To__c       = contact.Id;
        newProjectTask.RecordTypeId         = featureRecType;
        newProjectTask.Title__c             = 'Test Project Task';
        newProjectTask.Status__c            = 'Withdrawn';
        newProjectTask.Workplan__c          = workPlan.Id;
        newProjectTask.Start_Date__c = System.today();
        newProjectTask.Target_Resolution_Date__c = System.today() + 1;
        insert newProjectTask;

        
            newProjectTask.Status__c = 'In Progress';
            update newProjectTask;
        Test.stopTest();

    }

    @IsTest
    static void countProjectTasksUpdatedFromOpen() {
        Test.startTest();
        Project__c project      = [SELECT Id FROM Project__c LIMIT 1];
        Contact contact         = [SELECT Id FROM Contact LIMIT 1];
        Workplan__c workPlan    = [SELECT Id, Total_Open_Project_Tasks__c FROM Workplan__c LIMIT 1];
        Id featureRecType       = [SELECT Id FROM RecordType WHERE Name = 'Story'].Id;

        Project_Task__c newProjectTask = new Project_Task__c();
        newProjectTask.Alternative_Title__c = 'Feature Record';
        newProjectTask.Project__c           = project.Id;
        newProjectTask.Assigned_To__c       = contact.Id;
        newProjectTask.RecordTypeId         = featureRecType;
        newProjectTask.Title__c             = 'Test Project Task';
        newProjectTask.Status__c            = 'New';
        newProjectTask.Workplan__c          = workPlan.Id;
        newProjectTask.Start_Date__c = System.today();
        newProjectTask.Target_Resolution_Date__c = System.today() + 1;
        insert newProjectTask;

        
            newProjectTask.Status__c = 'Withdrawn';
            update newProjectTask;
        Test.stopTest();

    }

    @IsTest
    static void countProjectTasksWhenDeleted() {
        Test.startTest();
        Project__c project      = [SELECT Id FROM Project__c LIMIT 1];
        Contact contact         = [SELECT Id FROM Contact LIMIT 1];
        Workplan__c workPlan    = [SELECT Id, Total_Open_Project_Tasks__c FROM Workplan__c LIMIT 1];
        Id featureRecType       = [SELECT Id FROM RecordType WHERE Name = 'Story'].Id;

        Project_Task__c newProjectTask = new Project_Task__c();
        newProjectTask.Alternative_Title__c = 'Feature Record';
        newProjectTask.Project__c           = project.Id;
        newProjectTask.Assigned_To__c       = contact.Id;
        newProjectTask.RecordTypeId         = featureRecType;
        newProjectTask.Title__c             = 'Test Project Task';
        newProjectTask.Status__c            = 'New';
        newProjectTask.Workplan__c          = workPlan.Id;
        newProjectTask.Start_Date__c = System.today();
        newProjectTask.Target_Resolution_Date__c = System.today() + 1;
        insert newProjectTask;

        
            delete newProjectTask;
        Test.stopTest();
    }
    
    // CAPM-AGL-852-DV
   @IsTest
    static void assignNotificationTest(){
        // Query for the existing records
        Project__c projRecord = [SELECT Id, Name, OwnerId FROM Project__c WHERE Name = 'Test Project #A' LIMIT 1];
        Epic__c epicRecord = [SELECT Id, Name FROM Epic__c WHERE Name = 'Test Epic #A' LIMIT 1];
        Id qaRecType = [Select Id from RecordType WHERE Name = 'QA'].Id;
        Account ac = new Account(name ='Ulapp3');
        insert ac;
        Contact con = new Contact(LastName ='testCon32',AccountId = ac.Id, Email='test23@co23m.com');
        insert con;  
        
        // Create a new QA bug record
        Project_Task__c qaBugRecord = new Project_Task__c();
        qaBugRecord.Project__c = projRecord.Id;
        qaBugRecord.Epic__c = epicRecord.Id;
		qaBugRecord.SIT_Assigned_To__c = con.Id;
        qaBugRecord.UAT_Assigned_To__c = con.Id;
        qaBugRecord.RecordTypeId = qaRecType;
        qaBugRecord.Name = 'SIT';
        qaBugRecord.Status__c = 'SIT';
        insert qaBugRecord;
        
        Test.startTest();
    
        // Update the QA bug record to 'UAT'
        qaBugRecord.Status__c = 'UAT';
        update qaBugRecord;
    
        // Assertions after the 'UAT' update
        Project_Task__c uatUpdatedRecord = [SELECT Id, Status__c FROM Project_Task__c WHERE Id = :qaBugRecord.Id LIMIT 1];
        System.assertEquals('UAT', uatUpdatedRecord.Status__c, 'Status__c should be UAT after the update to UAT');
    
        // Make another update to the record to 'Prod Validation'
        qaBugRecord.Status__c = 'Prod Validation';
        update qaBugRecord;
    
        // Assertions after the 'Prod Validation' update
        Project_Task__c prodValidationUpdatedRecord = [SELECT Id, Status__c FROM Project_Task__c WHERE Id = :qaBugRecord.Id LIMIT 1];
        System.assertEquals('Prod Validation', prodValidationUpdatedRecord.Status__c, 'Status__c should be Prod Validation after the update to Prod Validation');

        Test.stopTest();
    }
}