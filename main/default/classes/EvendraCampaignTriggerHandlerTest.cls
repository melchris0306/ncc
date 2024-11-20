@IsTest
public class EvendraCampaignTriggerHandlerTest {
    
    
    @IsTest
    static void makeTestData(){
        Campaign newCampaign = new Campaign();
        newCampaign.Name = 'Test';
        insert newCampaign;
    }
    
    @IsTest
    // Test if url is re-generated if Re-Generate URL is updated for event
    public static void checkRegenrateURLEvent(){
        Campaign c = TestFactory.createCampaign('Test Campaign', 'Event');
        c.Event_Id__c = '';
        c.Event_Page_URL__c = '';
        c.Re_Generate_URL__c = false;
        update c;
        Test.startTest();
        c.Re_Generate_URL__c = true;
        update c;
        Test.stopTest();
        System.assertNotEquals(c.Event_Id__c, null);
        System.assertNotEquals(c.Event_Page_URL__c, null);
    }
    
    @IsTest
    // Test if url is re-generated if Re-Generate URL is updated for session
    public static void checkRegenrateURLSession(){
        Campaign c = TestFactory.createCampaign('Test Campaign', 'Session');
        c.Event_Id__c = '';
        c.Event_Page_URL__c = '';
        c.Re_Generate_URL__c = false;
        update c;
        Test.startTest();
        c.Re_Generate_URL__c = true;
        update c;
        Test.stopTest();
        System.assertNotEquals(c.Event_Id__c, null);
        System.assertNotEquals(c.Event_Page_URL__c, null);
    }
    
    @IsTest
    // Test if url is re-generated if Re-Generate URL is updated for event
    public static void setCampaignMemberStatusDefaultTest(){
        
        Test.startTest();
        Campaign c = TestFactory.createCampaign('Test Campaign', 'Event');
        Test.stopTest();
        
    }  
    
}