@isTest
public with sharing class MaterialsControllerTest {
    
    @TestSetup
    static void makeData(){
        Compass_Setting__c comp = TestDataFactory.createCSData(1);
        insert comp;
        
        Event__c parentCampaign = TestFactory.createEvent('Event');
        parentCampaign.Event_Id__c = 'AZJNzaeyah';
        parentCampaign.Start_Date_Time__c = DateTime.now();
        parentCampaign.End_Date_Time__c=DateTime.now().AddDays(1);
        parentCampaign.IsActive__c = true;
        parentCampaign.time_zone__c = 'EDT';
        update parentCampaign;
        
        General_Material_Group__c gmg = new General_Material_Group__c();
        gmg.Group_Header__c = 'Sample';
        gmg.Group_Description__c= 'Sample';
        gmg.Event__c =parentCampaign.id;
        insert gmg;
        
        
        ContentVersion material1 = TestFactory.createContentVersion('Material1', 'Test Material 1');
        String contentDocumentId1 = getContentDocumentId(material1);
        ContentDocumentLink cdl1 = TestFactory.createContentDocumentLink(contentDocumentId1, parentCampaign.Id, 'V', 'AllUsers');
        ContentDistribution cd1 = TestFactory.createContentDistribution(material1);
        
        ContentVersion material2 = TestFactory.createContentVersion('Material2', 'Test Material 2');
        String contentDocumentId2 = getContentDocumentId(material2);
        ContentDocumentLink cdl2 = TestFactory.createContentDocumentLink(contentDocumentId2, gmg.Id, 'V', 'AllUsers');
        ContentDistribution cd2 = TestFactory.createContentDistribution(material2);
        
        ContentVersion material3 = TestFactory.createContentVersion('Material3', 'Test Material 3');
        String contentDocumentId3 = getContentDocumentId(material3);
        ContentDocumentLink cdl3 = TestFactory.createContentDocumentLink(contentDocumentId3, gmg.Id, 'V', 'AllUsers');
        ContentDistribution cd4 = TestFactory.createContentDistribution(material3);
        
        
        
    }
    
    @isTest
    public static void testcheckEventMaterialDetails(){
        Event__c parentCampaign = [SElECT Id, Event_Id__c FROM Event__c WHERE Event_Id__c = 'AZJNzaeyah' LIMIT 1];
        Test.startTest();
        MaterialsController.checkEventMaterialDetails(parentCampaign.Event_Id__c);
        Test.stopTest();
    }
    
    
    @isTest
    public static void testgetEvent(){
        Event__c parentCampaign = [SElECT Id, Event_Id__c FROM Event__c WHERE Event_Id__c = 'AZJNzaeyah' LIMIT 1];
        Test.startTest();
        String result = MaterialsController.getEvent(parentCampaign.Event_Id__c);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetMaterials(){
        Event__c parentCampaign = [SElECT Id, Event_Id__c FROM Event__c WHERE Event_Id__c = 'AZJNzaeyah' LIMIT 1];
        Test.startTest();
        String result = MaterialsController.getMaterials(parentCampaign.Event_Id__c);
        Test.stopTest();
        
        List<MaterialsControllerHelper.MaterialWrapper> resultList = (List<MaterialsControllerHelper.MaterialWrapper>)JSON.deserializeStrict(result, List<MaterialsControllerHelper.MaterialWrapper>.class);
        System.assertEquals('Material1', resultList[0].Title);
        System.assertEquals('Test Material 1', resultList[0].Description);
        System.assertNotEquals(null, resultList[0].DownloadURL);
    }
    
    @isTest
    public static void testgetMaterialsGrouped(){
        Event__c parentCampaign = [SElECT Id, Event_Id__c FROM Event__c WHERE Event_Id__c = 'AZJNzaeyah' LIMIT 1];
        Test.startTest();
        String result = MaterialsController.getMaterialsGrouped(parentCampaign.Event_Id__c);
        Test.stopTest();
    }
    
    @isTest
    public static void testgetSessionMaterialsHelper(){
        Event__c parentCampaign = [SElECT Id, Event_Id__c FROM Event__c WHERE Event_Id__c = 'AZJNzaeyah' LIMIT 1];
        set<Id> idset = new set<id>();
        idset.add(parentCampaign.Id);
        Test.startTest();
        Map<Id,List<CCEEventWrapper.MaterialWrapper>> result = MaterialsControllerHelper.getSessionMaterialsHelper(idset);
        Test.stopTest();
    }
    
    
    public static String getContentDocumentId(ContentVersion cv){
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
    }
}