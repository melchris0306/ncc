@isTest
public class filterArticles_Test {
    /*@testSetup
    static void dataSetup() {
        Knowledge__kav knowledge = new Knowledge__kav();
        knowledge.Title = 'India Coronavirus Trajectory Looks Worse Than Other Countries';
        knowledge.UrlName = 'India-Coronavirus-Trajectory-Looks-Worse-Than-Other-Countries';
        insert knowledge;
        
        
        Knowledge__DataCategorySelection kADCS = new Knowledge__DataCategorySelection();
        kADCS.ParentId = knowledge.Id;
        kADCS.DataCategoryGroupName = 'CoronaFacts';
        kADCS.DataCategoryName = 'Consumer';                    
        insert kADCS;
    }*/
    
    static testMethod void filterArticles() {
        /*Knowledge__kav KnowledgeList = [ SELECT Id, Title, UrlName,KnowledgeArticleId FROM Knowledge__kav LIMIT 1 ];
        KbManagement.PublishingService.publishArticle(KnowledgeList.KnowledgeArticleId, true);
        Knowledge__DataCategorySelection DataCatrgoryList = [ SELECT Id,ParentId FROM Knowledge__DataCategorySelection LIMIT 1 ];
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse(); 
        
        String requestString='{ "target_audience":"Consumer","topic":"Treatment","source":"Other","source_attribtes":"Consensus_Opinion"}';
        req.requestBody = Blob.valueof(requestString);        
        RestContext.request = req; 
        RestContext.response= res;
        
        req.addHeader('httpMethod', 'POST');
        req.requestURI = '/services/apexrest/filterArticle/' +  KnowledgeList.Id;
        
        
        
        
        */
        
        Test.startTest();     
        FilterArticles.doGet();
        Test.stopTest();
    }
}