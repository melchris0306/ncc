/**
@revision Kyzer Buhay - Removed Project in Class name (ProjectIssueTriggerHandler_Test) to IssueTriggerHandler_Test
**/
@isTest
public class IssueTriggerHandler_Test {
   
    @TestSetup
    static void makeData(){
        List<Apex_Trigger_Switch__c> switchRecs = TestDataFactory.createAllTriggerSwitch();
        insert switchRecs;
        
        Compass_Setting__c comp = TestDataFactory.createCSData(1);
        insert comp;
        
        Event__c evt = TestFactory.createEvent('TestEvent');
        
        //Create Existing Contact
        String email = 'test@email.com';
        String token = '123';
        Contact con = new Contact();
        con.LastName = email;
        con.Email = email;
        //con.Login_Token__c = token;
        insert con;
        
        EmailTemplate e = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
        system.runAs( new User(Id = UserInfo.getUserId())){
        	insert e;
        }
        Compass_Setting__c cs = new Compass_Setting__c(Email_Template_Issue_Id__c = e.Id);
        system.runAs( new User(Id = UserInfo.getUserId())){
        	insert cs;
        }
    }

    @isTest
    static void testShouldDefault(){
        List<Issue__c> issues = new List<Issue__c>();  
        Event__c evt = [SELECT ID FROM Event__c LIMIT 1];
        issues.add(new Issue__c(
            Event__c = evt.Id,
            Raised_By_Email__c = 'test@email.com',
            Description__c = 'description',
            Status__c = 'New',
            Type__c = 'Domain Access Issue/User Sign-on Issues',
            Date_Raised__c = date.today()
        ));
        issues.add(new Issue__c(
            Event__c = evt.Id,
            Raised_By_Email__c = 'test@test.com',
            Description__c = 'description',
            Status__c = 'New',
            Type__c = 'Domain Access Issue/User Sign-on Issues',
            Date_Raised__c = date.today()
        ));
        Test.startTest();
            insert issues;
        Test.stopTest();
        for (Issue__c projIssue : [
            SELECT ID,
            Raised_By__c
            FROM Issue__c
        ]){
            System.assertNotEquals(null, projIssue.Raised_By__c, 'the raised_by did not default');
        }
        System.assertEquals(2, [SELECT ID FROM Issue__c].size(), 'the number of issues inserted is not equal');
        Update issues;
    }

    @isTest
    static void testShouldDefaultDuringUpdate(){
        List<Issue__c> issues = new List<Issue__c>();
    
        Event__c evt = [SELECT ID FROM Event__c LIMIT 1];
        issues.add(new Issue__c(
            Event__c = evt.Id,
            Raised_By_Email__c = 'test@email.com',
            Description__c = 'description',
            Status__c = 'New',
            Type__c = 'Domain Access Issue/User Sign-on Issues',
            Date_Raised__c = date.today()
        ));
        issues.add(new Issue__c(
            Event__c = evt.Id,
            Raised_By_Email__c = 'test@test.com',
            Description__c = 'description',
            Status__c = 'New',
            Type__c = 'Domain Access Issue/User Sign-on Issues',
            Date_Raised__c = date.today()
        ));
        insert issues;
        Test.startTest();
            for (Issue__c issue : issues){
                issue.Raised_By__c = null;
            }
            Update issues;
        Test.stopTest();
        for (Issue__c projIssue : [
            SELECT ID,
            Raised_By__c
            FROM Issue__c 
        ]){
            System.assertNotEquals(null, projIssue.Raised_By__c, 'the raised_by did not default');
        }
        System.assertEquals(2, [SELECT ID FROM Issue__c].size(), 'the number of issues inserted is not equal');
    }
    
    @isTest
    static void testIssueAddressed(){
        OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 1];
        Event__c evt = [SELECT Id, Email_Sender_Id__c FROM Event__c LIMIT 1];
        evt.Email_Sender_Id__c = owea.Id;
        update evt;
        
        Issue__c issue = new Issue__c(Event__c = evt.Id,
            Raised_By_Email__c = 'test@email.com',
            Description__c = 'description',
            Status__c = 'New',
            Type__c = 'Domain Access Issue/User Sign-on Issues',
            Date_Raised__c = date.today());
		insert issue;
        
        Test.startTest();
            issue.Status__c = 'Addressed';
        	update issue;
        Test.stopTest();
        
        //EmailMessage em = [SELECT Id, FromAddress FROM EmailMessage WHERE FromAddress =: owea.Address AND ToAddress =: issue.Raised_By_Email__c];
    	//System.assert(em != null);
    }
}