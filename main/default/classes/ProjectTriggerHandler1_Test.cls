@isTest
public class ProjectTriggerHandler1_Test {
    @testSetup static void createData() {
        //Create Project
        Project__c project = new Project__c(Name = 'Test Project',
                                                    Project_Code__c = 'test');
        insert project;
    }
    
    
    @isTest static void testUpdate(){
        
        Project__c project =  [SELECT Id, Project_Code__c, Agile_RAID_Page_URL__c from Project__c LIMIT 1];
        //Assert for Insert
        system.assertEquals('default/s/raid?id=test', Project.Agile_RAID_Page_URL__c);
        project.Project_Code__c = 'abcde';
        test.startTest();
        update project;
        test.stopTest();
        Project__c result =  [SELECT Id, Project_Code__c, Agile_RAID_Page_URL__c from Project__c LIMIT 1];
        //Assert for Update
        system.assertEquals('default/s/raid?id=abcde', result.Agile_RAID_Page_URL__c);
    }
}