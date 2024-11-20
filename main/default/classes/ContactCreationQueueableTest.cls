@isTest
public class ContactCreationQueueableTest {
    public static String emailBody = 'First Name: Johnny \n'+
        'Last Name: Doe \n'+
        'Email: userbd@ncc.example.com \n '+
        'Title: Test Title \n'+
        'City: City \n'+
        'State: State \n'+
        'Country: United States \n'+
        'Role: New Role \n'+
        'Manager: Iamca Cagurangan \n'+
        'Employment Status: 1099 \n'+
        'Start Date: 2021-07-20 \n'+
        'Aligned Project: none \n'+
        'Need Phone: Y \n'+
        'Need Laptop vs Computer: Y \n'+
        'Task for Skills Inventory: \n'+
        'Tasks for PIV and/or CAC: \n'+
        'Tasks for Tailored Resume: \n'+
        'Bio: \n'+
        'Brief Summary Section: \n'+
        'NCC Channel: \n'+
        'CPM NCC Internal Code Needed?: Y \n'+
        'CPM Title: Dev';
    
    public static Map<Id, Case> newCaseMap = new Map<Id, Case>();
    public static Map<Id, Case> oldCaseMap = new Map<Id, Case>();
    public static List<Case> newCaseList = new List<Case>();
    public static List<Case> oldCaseList = new List<Case>();
    
    @testSetup
    public static void setup() {
        
        Account ederaAcct = new Account(Name = 'Edera L3C');
        insert ederaAcct;        
        
    }
    
    @isTest
    static void testContactCreation() {       
        Case newCaseRec = new Case(Status = 'New', Description = emailBody, Subject = 'Onboarding New Hire');
        insert newCaseRec;
        
        oldCaseList = [select Id, Status, Description from Case];        
        oldCaseMap.put(oldCaseList[0].Id, oldCaseList[0]);
        oldCaseList[0].Status = 'In Progress';
        newCaseList.add(oldCaseList[0]);        
        update newCaseList;
        newCaseMap.put(oldCaseList[0].Id, oldCaseList[0]);
        
        Test.startTest();
        ContactCreationQueueable contactQueue = new ContactCreationQueueable(newCaseMap, oldCaseMap);
        Id jobId = System.enqueueJob(contactQueue);
        
        Test.stopTest();        
        Contact newContact = [select Id, Name, Email from Contact limit 1];
        System.assertEquals('Johnny Doe', newContact.Name);
        System.assertEquals('userbd@ncc.example.com', newContact.Email);
    }
    
    @isTest
    static void testContactCreationError() {     
        String emailBody = 'First Name: John \n'+
        'Last Name: Doe \n'+
        'Email: userbdncc.example.com \n '+
        'Title: Test Title \n'+
        'City: City \n'+
        'State: State \n'+
        'Country: United States \n'+
        'Role: New Role \n'+
        'Manager: Iamca Cagurangan \n'+
        'Employment Status: 1099 \n'+
        'Start Date: 2021-07-20 \n'+
        'Aligned Project: none \n'+
        'Need Phone: Y \n'+
        'Need Laptop vs Computer: Y \n'+
        'Task for Skills Inventory: \n'+
        'Tasks for PIV and/or CAC: \n'+
        'Tasks for Tailored Resume: \n'+
        'Bio: \n'+
        'Brief Summary Section: \n'+
        'NCC Channel: \n'+
        'CPM NCC Internal Code Needed?: Y \n'+
        'CPM Title: Dev';
        Case newCaseRec = new Case(Status = 'New', Description = emailBody);
        insert newCaseRec;
        oldCaseList = [select Id, Status, Description from Case];        
        oldCaseMap.put(oldCaseList[0].Id, oldCaseList[0]);
        oldCaseList[0].Status = 'In Progress';
        newCaseList.add(oldCaseList[0]);        
        update newCaseList;
        newCaseMap.put(oldCaseList[0].Id, oldCaseList[0]);
        
        Test.startTest();
        ContactCreationQueueable contactQueue = new ContactCreationQueueable(newCaseMap, oldCaseMap);
        Id jobId = System.enqueueJob(contactQueue);
        
        Test.stopTest();        
    }
}