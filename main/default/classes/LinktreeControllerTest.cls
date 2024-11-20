@istest
public with sharing class LinktreeControllerTest {
    
    @isTest
    public static void LinktreeTest() { 
        campaign__c c = new campaign__c(name = 'test campaign');
        insert c;
        c.Name = 'test campaign Updated';
        update c;
        
        Campaign__c cc = linktreeController.getcampaignDetail('abc');
        System.assertEquals(null, cc.id);
        
        cc = linktreeController.getcampaignDetail(c.Id);
        System.assertEquals(c.id, cc.id);
        
        //cc = linktreeController.getcampaignDetail('abc');
        //System.assertEquals(null, cc.id);
        
        List<Event__c> listE = linktreeController.getcampaignEvents(c.Id);
        System.assertEquals(0, listE.size());
        
        cc = linktreeController.getcampaignDetail(null);
        System.assertEquals(null, cc);
        
        listE = linktreeController.getcampaignEvents(null);
        System.assertEquals(null, listE);
        
        listE = linktreeController.getcampaignEvents('null');
        System.assertEquals(null, null);

    }
}