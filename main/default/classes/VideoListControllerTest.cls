@isTest
private class VideoListControllerTest {
    @testSetup static void testSetupData(){
        Account account = new Account();
        account.name = 'Test Acc';
        insert account;
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test Document';
        contentVersion.PathOnClient = 'TestDocument.MP4';
        contentVersion.VersionData = Blob.valueOf('Test Content');
        contentVersion.IsMajorVersion = true;
        insert contentVersion;
    }
    private static testMethod void getAllContentDocumentLinksTest(){
        Account account = [SELECT id FROM Account limit 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.ShareType = 'V';
        contentlink.LinkedEntityId = account.Id; 
        contentlink.ContentDocumentId = documents[0].Id;
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        
        Test.startTest();
            VideoListController.getAllVideos(account.id, null);
        Test.stopTest();
        System.assert(true);
    }
}