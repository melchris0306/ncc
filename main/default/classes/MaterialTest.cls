public class MaterialTest {
    
    @AuraEnabled 
    public static String getMaterials(){

        //ContentDistribution c = [SELECT ID, DistributionPublicUrl, ContentDocumentId, ContentDownloadURL FROM ContentDistribution 
        //                                   WHERE ContentDocumentId =: '06903000000OyY6AAK'];
        Event__c eventrec = [SELECT Id, Name FROM Event__c WHERE Event_Id__c =: '7RvETWUOkMc'];
        
        //ContentDocumentLink c = [SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.Description FROM ContentDocumentLink WHERE LinkedEntityId =: 'a4q03000000Go88AAC' Limit 1];
        
         
        return eventrec.Id;
    }
    
    
    
}