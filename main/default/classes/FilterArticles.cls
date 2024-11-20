@RestResource(urlMapping='/filterArticle/*')
global with sharing class FilterArticles 
{
    @HttpPost
    global static void  doGet() 
    {
        
        /*Network newNetwork =[SELECT Id, Name, Status, UrlPathPrefix FROM Network where Name like 'CoronaFacts' limit 1];
        Domain newdomain=[SELECT Id, DomainType, Domain FROM Domain limit 1];
        
        String sitebaseurl='https://'+newdomain.Domain+'/resource/';
        String communityURL='https://'+newdomain.Domain+'/'+newNetwork.UrlPathPrefix +'/s/article';
        
        RestRequest req = RestContext.request;
        Blob body = req.requestBody;
        String requestString = body.toString();
        FilterJson fj=(FilterJson)JSON.deserialize(requestString,FilterJson.class);
        System.debug('fj'+fj);
        
        List<Knowledge__kav> KnowledgeBase=Database.query('SELECT Description__c,URLname,Static_Resource__c,Source__c,Static_Resource_Name__c,Id,FirstPublishedDate,CreatedDate,Summary,Title,PublishStatus,KnowledgeArticleId  from Knowledge__kav WHERE PublishStatus=' + '\''+ 'Online' + '\' WITH  DATA CATEGORY CoronaFacts__c AT '+'('+ fj.target_audience +'__c'+ ','+ fj.topic +'__c'+','+ fj.source +'__c'+','+ fj.source_attribtes + '__c' + ')');
        list<ArticleData> filterArticles = new list<ArticleData>();
        
        for(Knowledge__kav TAL: KnowledgeBase )
        {
            ArticleData rec = new ArticleData();
            rec.img = sitebaseurl + TAL.Static_Resource__c;    
            rec.url= communityURL + TAL.URLname;
            rec.summary=TAL.Summary;
            rec.source=TAL.Source__c;
            rec.createddate=TAL.CreatedDate;
            rec.title=TAL.Title;
            rec.articleid=TAL.id;
            filterArticles.add(rec);
        }
        
        Data res = new Data();
        res.ArticleData = filterArticles;
        
        string jsonString = JSON.serialize(res);
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(jsonString);*/
        
    }
    
    /*public class Data
    {
        public list<ArticleData> ArticleData; 
    }
    
    public class FilterJson {
        
        public String target_audience;
        public String topic;
        public String source;
        public String source_attribtes;
    }
    
    public class ArticleData
    {
        public string img;
        public string url;
        public string summary;
        public string source;
        public dateTime createddate;
        public string title;
        public string articleid;
        
    }*/
}